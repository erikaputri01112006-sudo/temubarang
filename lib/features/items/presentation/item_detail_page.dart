import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temubarang/core/utils/date_helper.dart';
import 'package:temubarang/core/utils/whatsapp_helper.dart';
import 'package:temubarang/core/widgets/item_badge.dart';
import 'package:temubarang/features/items/domain/item_model.dart';
import 'package:temubarang/features/items/presentation/create_item_page.dart';
import 'package:temubarang/features/items/presentation/item_providers.dart';

class ItemDetailPage extends ConsumerStatefulWidget {
  const ItemDetailPage({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends ConsumerState<ItemDetailPage> {
  late Future<ItemModel> _itemFuture;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  void _loadItem() {
    _itemFuture = ref.read(itemRepositoryProvider).getItemById(widget.itemId);
  }

  void _refreshLists() {
    ref.invalidate(activeItemsProvider);
    ref.invalidate(myActiveItemsProvider);
    ref.invalidate(myResolvedItemsProvider);
  }

  Future<void> _markAsResolved(ItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tandai Laporan Selesai?'),
        content: const Text(
          'Laporan ini akan dipindahkan dari Beranda ke tab Riwayat Selesai, dan tombol WhatsApp akan disembunyikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(itemRepositoryProvider).markAsResolved(item.id);
      _refreshLists();
      if (!mounted) return;
      setState(() => _loadItem());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan ditandai selesai!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e')),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _deleteItem(ItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Laporan?'),
        content: const Text(
          'Laporan dan foto terkait akan dihapus secara permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(itemRepositoryProvider).deleteItem(item);
      _refreshLists();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dihapus.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus laporan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _contactViaWhatsapp(ItemModel item) async {
    final opened = await WhatsappHelper.openChat(
      phoneNumber: item.whatsappContact,
      itemTitle: item.title,
      itemTypeLabel: item.typeLabel,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat membuka WhatsApp. Pastikan WhatsApp atau browser terinstal.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
      ),
      body: FutureBuilder<ItemModel>(
        future: _itemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Laporan tidak ditemukan atau gagal dimuat.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(() => _loadItem()),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final item = snapshot.data!;
          final isOwner = currentUserId == item.userId;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (_, __, ___) => _noPhotoBox(theme),
                          ),
                        )
                      else
                        _noPhotoBox(theme),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                ItemBadge.type(item.type),
                                ItemBadge.status(item.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _InfoTile(
                              icon: Icons.category_outlined,
                              label: 'Kategori',
                              value: item.categoryName ?? 'Lainnya',
                            ),
                            _InfoTile(
                              icon: Icons.map_outlined,
                              label: 'Area / Zona',
                              value: item.areaName ?? '-',
                            ),
                            _InfoTile(
                              icon: Icons.location_on_outlined,
                              label: 'Lokasi Spesifik',
                              value: item.locationDetail,
                            ),
                            _InfoTile(
                              icon: Icons.calendar_today_outlined,
                              label: 'Tanggal Kejadian',
                              value:
                                  DateHelper.formatFullDate(item.incidentDate),
                            ),
                            _InfoTile(
                              icon: Icons.person_outline_rounded,
                              label: 'Dilaporkan Oleh',
                              value:
                                  '${item.reporterName ?? 'Pengguna'} • ${DateHelper.formatRelative(item.createdAt)}',
                            ),
                            const Divider(height: 28),
                            Text(
                              'Deskripsi & Ciri Barang',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                  child: _buildBottomActions(item, isOwner, theme),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomActions(ItemModel item, bool isOwner, ThemeData theme) {
    if (isOwner) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!item.isResolved) ...[
            FilledButton.icon(
              onPressed: _isActionLoading ? null : () => _markAsResolved(item),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Tandai Selesai'),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isActionLoading
                      ? null
                      : () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreateItemPage(existingItem: item),
                            ),
                          );
                          if (updated == true && mounted) {
                            setState(() => _loadItem());
                          }
                        },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isActionLoading ? null : () => _deleteItem(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Hapus'),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (item.isResolved) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Laporan ini sudah selesai. Kontak WhatsApp disembunyikan demi privasi.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return FilledButton.icon(
      onPressed: () => _contactViaWhatsapp(item),
      icon: const Icon(Icons.chat_rounded),
      label: Text(
        item.isLost
            ? 'Hubungi Pemilik via WhatsApp'
            : 'Hubungi Penemu via WhatsApp',
      ),
    );
  }

  Widget _noPhotoBox(ThemeData theme) {
    return Container(
      height: 180,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 44,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada foto terlampir',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
