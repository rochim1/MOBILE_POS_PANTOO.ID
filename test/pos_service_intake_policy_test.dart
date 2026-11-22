import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_service_intake.dart';

PosProduct service(String id, {String mode = 'auto', String unit = 'unit'}) => PosProduct(
  id: id, code: id, name: 'Jasa $id', category: 'Jasa', productType: 'service',
  serviceIntakeMode: mode, baseUnit: unit, tracksStock: false, price: 1000, stock: 0,
);

void main() {
  test('generic service is optional while trusted per-product overrides and profile defaults are preserved', () {
    expect(posServiceIntakeMode(service('a'), 'jasa'), 'none');
    expect(posServiceIntakeMode(service('a'), 'bengkel'), 'work_order');
    expect(posServiceIntakeMode(service('a'), 'laundry'), 'laundry');
    expect(posServiceIntakeMode(service('a', mode: 'none'), 'bengkel'), 'none');
    expect(posServiceIntakeMode(service('a', mode: 'work_order'), 'jasa'), 'work_order');
  });
  test('catalog snapshot round trips intake mode for offline use', () {
    final product = service('a', mode: 'work_order');
    expect(PosProduct.fromJson(product.toJson()).serviceIntakeMode, 'work_order');
  });
  test('generic service builds cart context without pretending its name is a work object', () {
    final data = buildPosServiceIntake({service('a'): 2}, 'jasa')!;
    expect(data['service_subject'], isNull);
    expect((data['service_lines'] as List).single['name'], 'Jasa a');
    expect((data['service_lines'] as List).single['quantity'], 2);
    expect(data['appointment_at'], isNull);
  });
  test('mixed laundry derives kg and item summaries independently', () {
    final data = buildPosServiceIntake({service('kg', mode: 'laundry', unit: 'kg'): 3.5, service('pcs', mode: 'laundry', unit: 'pcs'): 2}, 'jasa')!;
    expect(data['weight_kg'], 3.5);
    expect(data['item_count'], 2);
    expect((data['service_lines'] as List).first['pricing_basis'], 'per_kg');
    expect((data['service_lines'] as List).last['pricing_basis'], 'per_item');
  });
  test('goods-only cart does not inherit a service profile mandatory form', () {
    const goods = PosProduct(id: 'goods', code: 'g', name: 'Barang', category: '', price: 10, stock: 2);
    expect(buildPosServiceIntake({goods: 1}, 'bengkel'), isNull);
  });
  test('existing notes survive while direct stale schedules are removed', () {
    final cart = {service('a'): 2.0};
    final before = {'appointment_at': '2026-12-01T03:00:00.000Z', 'complaint': 'Catatan QA'};
    expect(buildPosServiceIntake(cart, 'jasa', existing: before)!['appointment_at'], isNull);
    expect(buildPosServiceIntake(cart, 'jasa', existing: before, reservation: true)!['appointment_at'], before['appointment_at']);
    expect(buildPosServiceIntake(cart, 'jasa', existing: before)!['complaint'], 'Catatan QA');
  });
}
