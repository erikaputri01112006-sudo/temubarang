import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temubarang/features/items/data/item_repository.dart';
import 'package:temubarang/features/items/domain/area_model.dart';
import 'package:temubarang/features/items/domain/category_model.dart';
import 'package:temubarang/features/items/domain/item_model.dart';

class ItemFilterState {
  const ItemFilterState({
    this.type,
    this.categoryId,
    this.areaId,
    this.searchQuery = '',
  });

  final String? type; // null = semua, 'lost', 'found'
  final int? categoryId;
  final int? areaId;
  final String searchQuery;

  bool get hasActiveFilters =>
      type != null ||
      categoryId != null ||
      areaId != null ||
      searchQuery.trim().isNotEmpty;

  ItemFilterState copyWith({
    String? type,
    bool clearType = false,
    int? categoryId,
    bool clearCategory = false,
    int? areaId,
    bool clearArea = false,
    String? searchQuery,
  }) {
    return ItemFilterState(
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      areaId: clearArea ? null : (areaId ?? this.areaId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ItemFilterNotifier extends Notifier<ItemFilterState> {
  @override
  ItemFilterState build() => const ItemFilterState();

  void setType(String? type) {
    state = state.copyWith(type: type, clearType: type == null);
  }

  void setCategory(int? categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null,
    );
  }

  void setArea(int? areaId) {
    state = state.copyWith(areaId: areaId, clearArea: areaId == null);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void resetAll() {
    state = const ItemFilterState();
  }
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(Supabase.instance.client);
});

final itemFilterProvider =
    NotifierProvider<ItemFilterNotifier, ItemFilterState>(
  ItemFilterNotifier.new,
);

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.read(itemRepositoryProvider).getCategories();
});

final areasProvider = FutureProvider<List<AreaModel>>((ref) async {
  return ref.read(itemRepositoryProvider).getAreas();
});

final activeItemsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final filter = ref.watch(itemFilterProvider);
  return ref.read(itemRepositoryProvider).getActiveItems(
        type: filter.type,
        categoryId: filter.categoryId,
        areaId: filter.areaId,
        searchQuery: filter.searchQuery,
      );
});

final myActiveItemsProvider = FutureProvider<List<ItemModel>>((ref) async {
  return ref.read(itemRepositoryProvider).getMyItems(status: 'open');
});

final myResolvedItemsProvider = FutureProvider<List<ItemModel>>((ref) async {
  return ref.read(itemRepositoryProvider).getMyItems(status: 'resolved');
});
