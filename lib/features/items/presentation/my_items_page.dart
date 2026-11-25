import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temubarang/core/widgets/empty_state_widget.dart';
import 'package:temubarang/features/items/domain/item_model.dart';
import 'package:temubarang/features/items/presentation/item_detail_page.dart';
import 'package:temubarang/features/items/presentation/item_providers.dart';
import 'package:temubarang/features/items/presentation/widgets/item_card.dart';

class MyItemsPage extends ConsumerWidget {
  const MyItemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Laporan Saya',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Selesai'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MyItemsList(
              provider: myActiveItemsProvider,
              emptyTitle: 'Belum Ada Laporan Aktif',
              emptySubtitle:
                  'Laporan barang hilang atau temuan yang Anda buat akan muncul di sini.',
            ),
            _MyItemsList(
              provider: myResolvedItemsProvider,
              emptyTitle: 'Belum Ada Riwayat Selesai',
              emptySubtitle:
                  'Laporan yang telah Anda tandai selesai akan tersimpan di tab ini.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MyItemsList extends ConsumerWidget {
  const _MyItemsList({
    required this.provider,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final FutureProvider<List<ItemModel>> provider;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(provider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(provider);
        await ref.read(provider.future);
      },
      child: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ListView(
          children: [
            const SizedBox(height: 80),
            EmptyStateWidget(
              icon: Icons.error_outline_rounded,
              title: 'Gagal Memuat Riwayat',
              subtitle: '$err',
              actionLabel: 'Coba Lagi',
              onAction: () => ref.invalidate(provider),
            ),
          ],
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                EmptyStateWidget(
                  icon: Icons.inventory_2_outlined,
                  title: emptyTitle,
                  subtitle: emptySubtitle,
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ItemCard(
                item: item,
                showStatusBadge: true,
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
    );
  }
}
