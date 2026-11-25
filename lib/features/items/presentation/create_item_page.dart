import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temubarang/core/utils/date_helper.dart';
import 'package:temubarang/core/utils/image_helper.dart';
import 'package:temubarang/core/utils/whatsapp_helper.dart';
import 'package:temubarang/features/items/domain/item_model.dart';
import 'package:temubarang/features/items/presentation/item_providers.dart';
import 'package:temubarang/features/profile/presentation/profile_provider.dart';

class CreateItemPage extends ConsumerStatefulWidget {
  const CreateItemPage({super.key, this.existingItem});

  final ItemModel? existingItem;

  @override
  ConsumerState<CreateItemPage> createState() => _CreateItemPageState();
}

class _CreateItemPageState extends ConsumerState<CreateItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _waController = TextEditingController();

  late String _type;
  int? _selectedCategoryId;
  int? _selectedAreaId;
  late DateTime _incidentDate;
  File? _pickedImage;
  bool _removeExistingImage = false;
  bool _waPrefilled = false;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    if (existing != null) {
      _type = existing.type;
      _titleController.text = existing.title;
      _locationController.text = existing.locationDetail;
      _descriptionController.text = existing.description;
      _waController.text = existing.whatsappContact;
      _selectedCategoryId = existing.categoryId;
      _selectedAreaId = existing.areaId;
      _incidentDate = existing.incidentDate.toLocal();
      _waPrefilled = true;
    } else {
      _type = 'lost';
      _incidentDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _waController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImageHelper.pickAndCompress(source);
      if (file == null || !mounted) return;
      setState(() {
        _pickedImage = file;
        _removeExistingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil foto: $e')),
      );
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil Foto dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _incidentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final hasExistingImage =
        !_removeExistingImage &&
        (widget.existingItem?.imageUrl?.isNotEmpty ?? false);
    final hasAnyImage = _pickedImage != null || hasExistingImage;

    // Kebijakan hasil wawancara: Foto wajib untuk barang temuan, opsional untuk barang hilang
    if (_type == 'found' && !hasAnyImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto wajib dilampirkan untuk laporan barang temuan.'),
        ),
      );
      return;
    }

    if (_selectedCategoryId == null || _selectedAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori dan area lokasi.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(itemRepositoryProvider);
      if (_isEditing) {
        await repo.updateItem(
          existingItem: widget.existingItem!,
          type: _type,
          title: _titleController.text,
          categoryId: _selectedCategoryId!,
          areaId: _selectedAreaId!,
          locationDetail: _locationController.text,
          incidentDate: _incidentDate,
          description: _descriptionController.text,
          whatsappContact: _waController.text,
          newImageFile: _pickedImage,
          removeExistingImage: _removeExistingImage,
        );
      } else {
        await repo.createItem(
          type: _type,
          title: _titleController.text,
          categoryId: _selectedCategoryId!,
          areaId: _selectedAreaId!,
          locationDetail: _locationController.text,
          incidentDate: _incidentDate,
          description: _descriptionController.text,
          whatsappContact: _waController.text,
          imageFile: _pickedImage,
        );
      }

      ref.invalidate(activeItemsProvider);
      ref.invalidate(myActiveItemsProvider);
      ref.invalidate(myResolvedItemsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Laporan berhasil diperbarui.'
                : 'Laporan berhasil dipublikasikan!',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan laporan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final areasAsync = ref.watch(areasProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final theme = Theme.of(context);

    if (!_waPrefilled) {
      final profileWa = profileAsync.valueOrNull?.whatsappNumber;
      if (profileWa != null && profileWa.isNotEmpty) {
        _waController.text = profileWa;
        _waPrefilled = true;
      }
    }

    final existingUrl =
        !_removeExistingImage ? widget.existingItem?.imageUrl : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Laporan' : 'Buat Laporan Baru',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Jenis Laporan',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'lost',
                    label: Text('Barang Hilang'),
                    icon: Icon(Icons.search_off_rounded),
                  ),
                  ButtonSegment(
                    value: 'found',
                    label: Text('Barang Temuan'),
                    icon: Icon(Icons.volunteer_activism_rounded),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (values) {
                  setState(() => _type = values.first);
                },
              ),
              const SizedBox(height: 20),
              Text(
                _type == 'found'
                    ? 'Foto Barang (Wajib)'
                    : 'Foto Barang (Opsional)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _PhotoPickerBox(
                pickedFile: _pickedImage,
                existingUrl: existingUrl,
                onPickTap: _showImageSourcePicker,
                onRemoveTap: () {
                  setState(() {
                    _pickedImage = null;
                    _removeExistingImage = true;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Judul / Nama Barang',
                  hintText: 'Contoh: Dompet Kulit Coklat / KTM Teknik',
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 4) {
                    return 'Judul minimal 4 karakter.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Gagal memuat kategori: $e'),
                data: (categories) {
                  final validCategoryId =
                      categories.any((c) => c.id == _selectedCategoryId)
                          ? _selectedCategoryId
                          : null;
                  return DropdownButtonFormField<int>(
                    value: validCategoryId,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                    validator: (val) =>
                        val == null ? 'Pilih kategori barang.' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              areasAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Gagal memuat area: $e'),
                data: (areas) {
                  final validAreaId =
                      areas.any((a) => a.id == _selectedAreaId)
                          ? _selectedAreaId
                          : null;
                  return DropdownButtonFormField<int>(
                    value: validAreaId,
                    decoration:
                        const InputDecoration(labelText: 'Area / Zona'),
                    items: areas
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedAreaId = val),
                    validator: (val) =>
                        val == null ? 'Pilih zona lokasi.' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Detail Lokasi Spesifik',
                  hintText: 'Contoh: Meja Kantin Pusat / Parkiran Gedung B',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'Masukkan detail lokasi (minimal 3 karakter).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Kejadian',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(DateHelper.formatFullDate(_incidentDate)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi & Ciri Khusus',
                  hintText:
                      'Jelaskan warna, merek, stiker, atau kondisi barang...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Deskripsi minimal 10 karakter agar mudah dikenali.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _waController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor WhatsApp Kontak',
                  hintText: 'Contoh: 081234567890',
                  prefixIcon: Icon(Icons.chat_outlined),
                  helperText:
                      'Bisa menggunakan nomor Anda atau nomor pos keamanan/titipan.',
                ),
                validator: (value) {
                  if (value == null || !WhatsappHelper.isValidNumber(value)) {
                    return 'Masukkan nomor WhatsApp yang valid (10–15 digit).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Simpan Perubahan' : 'Publikasikan Laporan',
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPickerBox extends StatelessWidget {
  const _PhotoPickerBox({
    required this.pickedFile,
    required this.existingUrl,
    required this.onPickTap,
    required this.onRemoveTap,
  });

  final File? pickedFile;
  final String? existingUrl;
  final VoidCallback onPickTap;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage =
        pickedFile != null || (existingUrl != null && existingUrl!.isNotEmpty);

    if (!hasImage) {
      return InkWell(
        onTap: onPickTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 170,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 38,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Ketuk untuk tambah foto',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Foto otomatis dikompresi agar hemat kuota',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: pickedFile != null
                ? Image.file(pickedFile!, fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: existingUrl!,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: onPickTap,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Ganti'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onRemoveTap,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Hapus Foto',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
