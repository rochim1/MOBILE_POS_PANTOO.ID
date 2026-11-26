import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/utils/stock_quantity_input.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transfer.dart';

void main() {
  test('store and display must share a nonempty outlet, other routes stay unchanged', () {
    final store={'warehouse_type':'store','linked_toko_id':'A'};
    final ownDisplay={'warehouse_type':'display','linked_toko_id':'A'};
    final otherDisplay={'warehouse_type':'display','linked_toko_id':'B'};
    expect(transferOutletPairError(store,ownDisplay),isNull);
    expect(transferOutletPairError(ownDisplay,store),isNull);
    expect(transferOutletPairError(store,otherDisplay),isNotNull);
    expect(transferOutletPairError(otherDisplay,store),isNotNull);
    expect(transferOutletPairError(store,{'warehouse_type':'display'}),isNotNull);
    expect(transferOutletPairError({'warehouse_type':'central'},otherDisplay),isNull);
    expect(transferOutletPairError(store,{'warehouse_type':'store','linked_toko_id':'B'}),isNull);
    expect(transferOutletPairError(store,null),isNull);
  });
  test('quantity zero starts empty, integers do not show unnecessary .0, decimal remains exact', () {
    expect(stockQuantityText(0.0),'');expect(stockQuantityText('0'),'');
    expect(stockQuantityText(25.0),'25');expect(stockQuantityText(0.25),'0.25');
    expect(stockQuantityText(null),'');
  });
  for(final pair in [('025','25'),('00025','25'),('000.5','0.5'),('00,5','0,5'),('0.05','0.05'),('0','0'),('',''),('-025','-25')]) {
    test('quantity input ${pair.$1} becomes ${pair.$2} without deleting decimals', () {
      final result=const StockQuantityInputFormatter().formatEditUpdate(
        const TextEditingValue(text:'0'),TextEditingValue(text:pair.$1,selection:TextSelection.collapsed(offset:pair.$1.length)));
      expect(result.text,pair.$2);expect(result.selection.baseOffset,pair.$2.length);
    });
  }
}
