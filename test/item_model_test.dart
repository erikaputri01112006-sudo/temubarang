import 'package:flutter_test/flutter_test.dart';
import 'package:temubarang/features/items/domain/item_model.dart';

void main() {
  group('ItemModel', () {
    test('mem-parsing JSON Supabase beserta relasi join dengan benar', () {
      final json = {
        'id': 'item-123',
        'user_id': 'user-456',
        'category_id': 2,
        'area_id': 3,
        'type': 'found',
        'title': 'Kunci Motor Honda',
        'description': 'Ditemukan di meja kantin dengan gantungan biru.',
        'location_detail': 'Kantin Pusat Meja 4',
        'incident_date': '2026-11-24T08:00:00Z',
        'image_url': 'https://example.supabase.co/storage/v1/object/public/item-images/u/1.jpg',
        'whatsapp_contact': '6281234567890',
        'status': 'open',
        'created_at': '2026-11-24T09:00:00Z',
        'profiles': {'full_name': 'Siti Aminah'},
        'categories': {'id': 2, 'name': 'Kunci', 'icon_name': 'key'},
        'areas': {'id': 3, 'name': 'Perpustakaan & Kantin'},
      };

      final item = ItemModel.fromJson(json);

      expect(item.id, 'item-123');
      expect(item.isFound, isTrue);
      expect(item.isLost, isFalse);
      expect(item.isResolved, isFalse);
      expect(item.typeLabel, 'Barang Temuan');
      expect(item.reporterName, 'Siti Aminah');
      expect(item.categoryName, 'Kunci');
      expect(item.areaName, 'Perpustakaan & Kantin');
    });
  });
}
