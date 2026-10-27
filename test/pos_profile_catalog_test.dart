import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_profile_catalog.dart';

void main() {
  test('semua profil dan preset sama dengan katalog web', () {
    final catalog =
        jsonDecode(
              File(
                '../front_end_template/src/data/pos_profiles.json',
              ).readAsStringSync(),
            )
            as Map;
    final profiles = catalog['profiles'] as List;
    expect(posProfileIds, profiles.map((p) => p['value']).toList());
    for (final p in profiles) {
      expect(posProfileLabels[p['value']], p['label']);
      expect(
        posProfileFeatures(p['value'] as String),
        Map<String, bool>.from(p['features'] as Map),
      );
    }
    expect(
      posFeatureOptions.map((f) => f['key']).toSet(),
      (catalog['features'] as List).map((f) => f['key']).toSet(),
    );
  });
  test(
    'salon mendukung reservasi, staf dan stok produk tanpa dapur/kendaraan',
    () {
      final features = posProfileFeatures('salon');
      expect(features['use_service_order'], isTrue);
      expect(features['use_appointments'], isTrue);
      expect(features['use_technicians'], isTrue);
      expect(features['track_stock'], isTrue);
      expect(features['use_vehicle_data'], isFalse);
      expect(features['use_kitchen_flow'], isFalse);
      expect(posFulfillmentOptions('salon', features), [
        'take_away',
        'reservation',
      ]);
    },
  );
  test('custom mempertahankan pilihan dan jasa tetap melacak stok', () {
    final original = posProfileFeatures('salon');
    original['use_delivery'] = true;
    expect(posProfileFeatures('custom', current: original), original);
    expect(posProfileFeatures('jasa')['track_stock'], isTrue);
    original['track_stock'] = false;
    expect(posProfileFeatures('salon')['track_stock'], isTrue);
  });
}
