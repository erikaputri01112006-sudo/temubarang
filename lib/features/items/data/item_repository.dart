import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temubarang/core/config/app_config.dart';
import 'package:temubarang/core/utils/whatsapp_helper.dart';
import 'package:temubarang/features/items/domain/area_model.dart';
import 'package:temubarang/features/items/domain/category_model.dart';
import 'package:temubarang/features/items/domain/item_model.dart';

class ItemRepository {
  ItemRepository(this._client);

  final SupabaseClient _client;

  static const String _itemSelect =
      '*, profiles(full_name), categories(id, name, icon_name), areas(id, name)';

  Future<List<CategoryModel>> getCategories() async {
    final data = await _client.from('categories').select().order('id');
    return (data as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AreaModel>> getAreas() async {
    final data = await _client.from('areas').select().order('id');
    return (data as List<dynamic>)
        .map((e) => AreaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ItemModel>> getActiveItems({
    String? type,
    int? categoryId,
    int? areaId,
    String? searchQuery,
  }) async {
    var query = _client.from('items').select(_itemSelect).eq('status', 'open');

    if (type != null && type.isNotEmpty) {
      query = query.eq('type', type);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (areaId != null) {
      query = query.eq('area_id', areaId);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final sanitized = searchQuery
          .trim()
          .replaceAll(RegExp(r'[(),]'), ' ')
          .trim();
      if (sanitized.isNotEmpty) {
        query = query.or(
          'title.ilike.%$sanitized%,'
          'description.ilike.%$sanitized%,'
          'location_detail.ilike.%$sanitized%',
        );
      }
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List<dynamic>)
        .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ItemModel>> getMyItems({required String status}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('items')
        .select(_itemSelect)
        .eq('user_id', userId)
        .eq('status', status)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ItemModel> getItemById(String id) async {
    final data = await _client
        .from('items')
        .select(_itemSelect)
        .eq('id', id)
        .single();
    return ItemModel.fromJson(data);
  }

  Future<String> _uploadImage(File file, String userId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';

    await _client.storage.from(AppConfig.itemImagesBucket).upload(
          path,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    return _client.storage.from(AppConfig.itemImagesBucket).getPublicUrl(path);
  }

  Future<void> _deleteImageByUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    final marker = '/object/public/${AppConfig.itemImagesBucket}/';
    final idx = imageUrl.indexOf(marker);
    if (idx == -1) return;

    final storagePath = imageUrl.substring(idx + marker.length);
    if (storagePath.isEmpty) return;

    try {
      await _client.storage.from(AppConfig.itemImagesBucket).remove([
        storagePath,
      ]);
    } catch (_) {
      // Abaikan kegagalan pembersihan file agar aksi utama tidak terblokir
    }
  }

  Future<void> createItem({
    required String type,
    required String title,
    required int categoryId,
    required int areaId,
    required String locationDetail,
    required DateTime incidentDate,
    required String description,
    required String whatsappContact,
    File? imageFile,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Anda harus masuk terlebih dahulu.');
    }

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, userId);
    }

    await _client.from('items').insert({
      'user_id': userId,
      'category_id': categoryId,
      'area_id': areaId,
      'type': type,
      'title': title.trim(),
      'description': description.trim(),
      'location_detail': locationDetail.trim(),
      'incident_date': incidentDate.toUtc().toIso8601String(),
      'image_url': imageUrl,
      'whatsapp_contact': WhatsappHelper.normalizeNumber(whatsappContact),
      'status': 'open',
    });
  }

  Future<void> updateItem({
    required ItemModel existingItem,
    required String type,
    required String title,
    required int categoryId,
    required int areaId,
    required String locationDetail,
    required DateTime incidentDate,
    required String description,
    required String whatsappContact,
    File? newImageFile,
    bool removeExistingImage = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Anda harus masuk terlebih dahulu.');
    }

    String? finalImageUrl = existingItem.imageUrl;
    if (newImageFile != null) {
      finalImageUrl = await _uploadImage(newImageFile, userId);
      await _deleteImageByUrl(existingItem.imageUrl);
    } else if (removeExistingImage) {
      await _deleteImageByUrl(existingItem.imageUrl);
      finalImageUrl = null;
    }

    await _client
        .from('items')
        .update({
          'category_id': categoryId,
          'area_id': areaId,
          'type': type,
          'title': title.trim(),
          'description': description.trim(),
          'location_detail': locationDetail.trim(),
          'incident_date': incidentDate.toUtc().toIso8601String(),
          'image_url': finalImageUrl,
          'whatsapp_contact': WhatsappHelper.normalizeNumber(whatsappContact),
        })
        .eq('id', existingItem.id);
  }

  Future<void> markAsResolved(String itemId) async {
    await _client
        .from('items')
        .update({'status': 'resolved'})
        .eq('id', itemId);
  }

  Future<void> deleteItem(ItemModel item) async {
    await _client.from('items').delete().eq('id', item.id);
    await _deleteImageByUrl(item.imageUrl);
  }
}
