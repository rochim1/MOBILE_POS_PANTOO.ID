import '../../../../domain/repositories/pos_inventory_repository.dart';

typedef InventoryPermissionCheck = bool Function(String action);

class PosInventoryActionPolicy {
  const PosInventoryActionPolicy._();

  static List<String> available({
    required PosInventoryDocumentType type,
    required String status,
    required InventoryPermissionCheck can,
    bool canReceiveTransfer = false,
  }) {
    final actions = <String>[];
    final editable = switch (type) {
      PosInventoryDocumentType.purchase ||
      PosInventoryDocumentType.opname ||
      PosInventoryDocumentType.transfer =>
        status == 'draft' || status == 'rejected',
      PosInventoryDocumentType.scrap => status == 'draft',
    };
    if (editable && can('update')) actions.add('edit');
    if (status == 'draft' &&
        can('submit') &&
        type != PosInventoryDocumentType.scrap) {
      actions.add('submit');
    }
    if ((status == 'pending' || status == 'submitted') && can('approve')) {
      actions.add('approve');
    }
    if ((status == 'pending' || status == 'submitted') && can('reject')) {
      actions.add('reject');
    }
    if (type == PosInventoryDocumentType.purchase &&
        (status == 'approved' || status == 'partially_received') &&
        can('receive')) {
      actions.add('receive_purchase');
    }
    if (type == PosInventoryDocumentType.opname &&
        status == 'approved' &&
        can('post')) {
      actions.add('post');
    }
    if (type == PosInventoryDocumentType.transfer &&
        status == 'approved' &&
        can('post')) {
      actions.add('post');
    }
    if (type == PosInventoryDocumentType.scrap &&
        status == 'draft' &&
        can('approve')) {
      actions.add('approve');
    }
    if (type == PosInventoryDocumentType.scrap &&
        (status == 'draft' || status == 'approved') &&
        can('reject')) {
      actions.add('reject');
    }
    if (type == PosInventoryDocumentType.scrap &&
        status == 'approved' &&
        can('process')) {
      actions.add('process');
    }
    final cancellable = switch (type) {
      PosInventoryDocumentType.opname => const {
        'draft',
        'submitted',
        'approved',
        'rejected',
      }.contains(status),
      PosInventoryDocumentType.transfer => const {
        'draft',
        'submitted',
        'approved',
        'rejected',
        'in_transit',
        'posted',
      }.contains(status),
      _ => false,
    };
    if (cancellable && can('cancel')) actions.add('cancel');
    final deletable = switch (type) {
      PosInventoryDocumentType.purchase =>
        status == 'draft' || status == 'rejected',
      PosInventoryDocumentType.opname || PosInventoryDocumentType.transfer =>
        const {'draft', 'rejected', 'cancelled'}.contains(status),
      PosInventoryDocumentType.scrap => status != 'completed',
    };
    if (deletable && can('delete')) actions.add('delete');
    if (type == PosInventoryDocumentType.transfer &&
        status == 'in_transit' &&
        canReceiveTransfer) {
      actions.add('receive_transfer');
    }
    return actions;
  }
}
