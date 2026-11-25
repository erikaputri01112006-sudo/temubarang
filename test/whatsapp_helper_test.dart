import 'package:flutter_test/flutter_test.dart';
import 'package:temubarang/core/utils/whatsapp_helper.dart';

void main() {
  group('WhatsappHelper', () {
    test('menormalisasi awalan 08 menjadi 628', () {
      expect(
        WhatsappHelper.normalizeNumber('0812-3456-7890'),
        '6281234567890',
      );
    });

    test('menormalisasi awalan 8 menjadi 628', () {
      expect(
        WhatsappHelper.normalizeNumber('81234567890'),
        '6281234567890',
      );
    });

    test('mempertahankan awalan +62 sebagai 62', () {
      expect(
        WhatsappHelper.normalizeNumber('+62 812 3456 7890'),
        '6281234567890',
      );
    });

    test('memvalidasi panjang nomor WhatsApp', () {
      expect(WhatsappHelper.isValidNumber('081234567890'), isTrue);
      expect(WhatsappHelper.isValidNumber('08123'), isFalse);
    });

    test('membentuk URI wa.me dengan pesan ter-encode', () {
      final uri = WhatsappHelper.buildWhatsappUri(
        phoneNumber: '081234567890',
        itemTitle: 'Dompet Hitam',
        itemTypeLabel: 'Barang Hilang',
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/6281234567890');
      expect(uri.queryParameters['text'], contains('Dompet Hitam'));
    });
  });
}
