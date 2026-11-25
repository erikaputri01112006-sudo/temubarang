import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temubarang/core/widgets/empty_state_widget.dart';
import 'package:temubarang/features/items/presentation/item_detail_page.dart';
import 'package:temubarang/features/items/presentation/item_providers.dart';
import 'package:temubarang/features/items/presentation/widgets/item_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(itemFilterProvider);
    final itemsAsync = ref.watch(activeItemsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TemuBarang',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Filter Kategori & Area',
            onPressed: _openFilterSheet,
            icon: Badge(
              isLabelVisible:
                  filter.categoryId != null || filter.areaId != null,
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                ref.read(itemFilterProvider.notifier).setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Cari nama barang, ciri, atau lokasi...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: filter.searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(itemFilterProvider.notifier)
                              .setSearchQuery('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: filter.type == null,
                  onSelected: (_) =>
                      ref.read(itemFilterProvider.notifier).setType(null),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Barang Hilang'),
                  selected: filter.type == 'lost',
                  onSelected: (_) =>
                      ref.read(itemFilterProvider.notifier).setType('lost'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Barang Temuan'),
                  selected: filter.type == 'found',
                  onSelected: (_) =>
                      ref.read(itemFilterProvider.notifier).setType('found'),
                ),
                ...categoriesAsync.maybeWhen(
                  data: (categories) => categories.map((cat) {
                    final selected = filter.categoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        avatar: Icon(cat.icon, size: 16),
                        label: Text(cat.name),
                        selected: selected,
                        onSelected: (isSelected) {
                          ref
                              .read(itemFilterProvider.notifier)
                              .setCategory(isSelected ? cat.id : null);
                        },
                      ),
                    );
                  }),
                  orElse: () => const [],
                ),
              ],
            ),
          ),
          if (filter.areaId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Filter area aktif',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(itemFilterProvider.notifier).resetAll();
                    },
                    child: const Text('Reset Filter'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(activeItemsProvider);
                await ref.read(activeItemsProvider.future);
              },
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ListView(
                  children: [
                    const SizedBox(height: 80),
                    EmptyStateWidget(
                      icon: Icons.wifi_off_rounded,
                      title: 'Gagal Memuat Laporan',
                      subtitle: '$err',
                      actionLabel: 'Coba Lagi',
                      onAction: () => ref.invalidate(activeItemsProvider),
                    ),
                  ],
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 60),
                        EmptyStateWidget(
                          icon: Icons.search_off_rounded,
                          title: filter.hasActiveFilters
                              ? 'Laporan Tidak Ditemukan'
                              : 'Belum Ada Laporan Aktif',
                          subtitle: filter.hasActiveFilters
                              ? 'Coba ubah kata kunci pencarian atau reset filter Anda.'
                              : 'Jadilah yang pertama melaporkan barang hilang atau temuan di sekitar Anda.',
                          actionLabel: filter.hasActiveFilters
                              ? 'Reset Filter'
                              : null,
                          onAction: filter.hasActiveFilters
                              ? () {
                                  _searchController.clear();
                                  ref
                                      .read(itemFilterProvider.notifier)
                                      .resetAll();
                                }
                              : null,
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ItemCard(
                        item: item,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailPage(itemId: item.id),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(itemFilterProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final areasAsync = ref.watch(areasProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Filter Laporan',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(itemFilterProvider.notifier).resetAll();
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Kategori Barang',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Gagal memuat kategori.'),
                data: (categories) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final selected = filter.categoryId == cat.id;
                    return ChoiceChip(
                      label: Text(cat.name),
                      selected: selected,
                      onSelected: (val) {
                        ref
                            .read(itemFilterProvider.notifier)
                            .setCategory(val ? cat.id : null);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Area / Zona Lokasi',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              areasAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Gagal memuat daftar area.'),
                data: (areas) => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: areas.map((area) {
                    final selected = filter.areaId == area.id;
                    return ChoiceChip(
                      label: Text(area.name),
                      selected: selected,
                      onSelected: (val) {
                        ref
                            .read(itemFilterProvider.notifier)
                            .setArea(val ? area.id : null);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Terapkan Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
