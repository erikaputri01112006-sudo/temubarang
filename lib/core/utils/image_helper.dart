import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Helper untuk memilih foto dari kamera/galeri dan mengompresinya
/// agar hemat kuota Supabase Storage Free Tier (1 GB).
class ImageHelper {
  ImageHelper._();

  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickAndCompress(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) return null;

    final originalFile = File(picked.path);
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'temubarang_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final compressed = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      targetPath,
      minWidth: 1024,
      minHeight: 1024,
      quality: 72,
      format: CompressFormat.jpeg,
    );

    if (compressed != null) {
      return File(compressed.path);
    }
    return originalFile;
  }
}
