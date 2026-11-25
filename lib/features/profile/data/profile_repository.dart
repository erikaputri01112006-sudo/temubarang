import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temubarang/core/utils/whatsapp_helper.dart';
import 'package:temubarang/features/profile/domain/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<UserProfile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfile({
    required String fullName,
    required String whatsappNumber,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Sesi login tidak ditemukan.');
    }

    final normalizedWa = WhatsappHelper.normalizeNumber(whatsappNumber);

    final data = await _client
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'whatsapp_number': normalizedWa,
        })
        .eq('id', user.id)
        .select()
        .single();

    return UserProfile.fromJson(data);
  }
}
