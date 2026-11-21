import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_product_import_repository.dart';

void main() {
  test('mobile template uses existing inventory headers and no stock opening', () {
    final template = PosProductImportRepository.template;
    expect(template, contains('nama_inventaris'));
    expect(template, contains('harga_jual'));
    expect(template.split('\n').first.split(','), isNot(contains('stok')));
  });
  test('same file produces stable retry identity', () {
    final bytes = utf8.encode('nama_inventaris\nProduk\n');
    expect(PosProductImportRepository.requestId(bytes), PosProductImportRepository.requestId(bytes));
    expect(PosProductImportRepository.requestId(bytes), isNot(PosProductImportRepository.requestId(utf8.encode('changed'))));
  });
  test('import result preserves row diagnostics and opening stock handoff ids', () {
    final r=PosProductImportResult.fromJson({'importedCount':2,'failedCount':1,'skippedCount':0,'totalProcessed':3,'stockItemIds':['stock-id'],'errors':[{'row':4,'field':'harga_jual','message':'Invalid'}],'warnings':[]});
    expect(r.importedCount,2); expect(r.stockItemIds,['stock-id']); expect(r.errors.single['row'],4);
  });
}
