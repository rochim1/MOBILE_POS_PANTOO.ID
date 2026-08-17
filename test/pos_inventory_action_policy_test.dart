import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_inventory_action_policy.dart';

void main() {
  bool allowAll(String _) => true;

  group('PosInventoryActionPolicy', () {
    test('purchase rejected can be edited or deleted but not submitted', () {
      final actions = PosInventoryActionPolicy.available(
        type: PosInventoryDocumentType.purchase,
        status: 'rejected',
        can: allowAll,
      );

      expect(actions, containsAll(<String>['edit', 'delete']));
      expect(actions, isNot(contains('submit')));
    });

    test('opname rejected can be corrected, cancelled, or deleted', () {
      final actions = PosInventoryActionPolicy.available(
        type: PosInventoryDocumentType.opname,
        status: 'rejected',
        can: allowAll,
      );

      expect(actions, containsAll(<String>['edit', 'cancel', 'delete']));
      expect(actions, isNot(contains('submit')));
    });

    test('transfer in transit can be received or cancelled', () {
      final actions = PosInventoryActionPolicy.available(
        type: PosInventoryDocumentType.transfer,
        status: 'in_transit',
        can: allowAll,
        canReceiveTransfer: true,
      );

      expect(actions, containsAll(<String>['cancel', 'receive_transfer']));
      expect(actions, isNot(contains('post')));
    });

    test('posted transfer can be reversed but not deleted', () {
      final actions = PosInventoryActionPolicy.available(
        type: PosInventoryDocumentType.transfer,
        status: 'posted',
        can: allowAll,
      );

      expect(actions, contains('cancel'));
      expect(actions, isNot(contains('delete')));
      expect(actions, isNot(contains('receive_transfer')));
    });

    test('scrap draft supports edit, approve, reject, and delete', () {
      final actions = PosInventoryActionPolicy.available(
        type: PosInventoryDocumentType.scrap,
        status: 'draft',
        can: allowAll,
      );

      expect(
        actions,
        containsAll(<String>['edit', 'approve', 'reject', 'delete']),
      );
      expect(actions, isNot(contains('submit')));
    });

    test('approved scrap can be rejected or processed but not edited', () {
      final actions = PosInventoryActionPolicy.available(
        type: PosInventoryDocumentType.scrap,
        status: 'approved',
        can: allowAll,
      );

      expect(actions, containsAll(<String>['reject', 'process', 'delete']));
      expect(actions, isNot(contains('edit')));
    });

    test('completed scrap has no mutable actions', () {
      final actions = PosInventoryActionPolicy.available(
        type: PosInventoryDocumentType.scrap,
        status: 'completed',
        can: allowAll,
      );

      expect(actions, isEmpty);
    });

    test('permissions still gate every server action', () {
      final actions = PosInventoryActionPolicy.available(
        type: PosInventoryDocumentType.purchase,
        status: 'draft',
        can: (_) => false,
      );

      expect(actions, isEmpty);
    });
  });
}
