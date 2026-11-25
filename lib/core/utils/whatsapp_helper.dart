import 'package:url_launcher/url_launcher.dart';

/// Utilitas untuk normalisasi nomor WhatsApp dan membuka chat `wa.me`.
class WhatsappHelper {
  WhatsappHelper._();

  /// Menormalisasi nomor HP Indonesia (mis. `0812-3456-7890` -> `6281234567890`).
  static String normalizeNumber(String rawInput) {
    var digits = rawInput.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    } else if (digits.startsWith('8')) {
      digits = '62$digits';
    }
    return digits;
  }

  /// Memvalidasi panjang minimal nomor WhatsApp (10-15 digit).
  static bool isValidNumber(String rawInput) {
    final normalized = normalizeNumber(rawInput);
    return normalized.length >= 10 && normalized.length <= 15;
  }

  /// Memformat nomor `628...` menjadi tampilan yang mudah dibaca (`+62 8...`).
  static String formatDisplay(String rawInput) {
    final normalized = normalizeNumber(rawInput);
    if (normalized.isEmpty) return '-';
    return '+$normalized';
  }

  /// Membentuk URL `https://wa.me/...` dengan pesan templat Bahasa Indonesia.
  static Uri buildWhatsappUri({
    required String phoneNumber,
    required String itemTitle,
    required String itemTypeLabel,
  }) {
    final normalized = normalizeNumber(phoneNumber);
    final message =
        'Halo, saya melihat laporan $itemTypeLabel "$itemTitle" di aplikasi TemuBarang. Apakah masih bisa dikonfirmasi lebih lanjut?';
    return Uri.https('wa.me', '/$normalized', {'text': message});
  }

  /// Membuka aplikasi WhatsApp atau browser eksternal.
  static Future<bool> openChat({
    required String phoneNumber,
    required String itemTitle,
    required String itemTypeLabel,
  }) async {
    final normalized = normalizeNumber(phoneNumber);
    if (normalized.isEmpty) return false;

    final uri = buildWhatsappUri(
      phoneNumber: normalized,
      itemTitle: itemTitle,
      itemTypeLabel: itemTypeLabel,
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
