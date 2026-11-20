import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_opening_stock_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('opening retry survives reload, cannot overwrite pending payload or cross identity', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final a = OpeningStockDraft(prefs, 'server|tenant|owner|operator');
    final payload = {'tanggal': '2026-11-20', 'items': [{'inventaris_id': 'item', 'qty': 12}]};
    final first = await a.prepare(payload);
    final reloaded = OpeningStockDraft(prefs, 'server|tenant|owner|operator');
    expect(await reloaded.prepare(payload), first);
    expect(reloaded.pending, first);
    expect(OpeningStockDraft(prefs, 'server|other|owner|operator').pending, isNull);
    await expectLater(a.prepare({'items': []}), throwsStateError);
    await a.clear();
    expect(a.pending, isNull);
  });
}
