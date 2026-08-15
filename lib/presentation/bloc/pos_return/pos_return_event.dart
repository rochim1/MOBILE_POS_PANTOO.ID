import 'package:equatable/equatable.dart';

abstract class PosReturnEvent extends Equatable {
  const PosReturnEvent();
  @override
  List<Object?> get props => [];
}

class LoadReturns extends PosReturnEvent {
  final String? search;
  final String? status;
  const LoadReturns({this.search, this.status});
  @override
  List<Object?> get props => [search, status];
}

class SearchInvoice extends PosReturnEvent {
  final String invoice;
  const SearchInvoice(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

class SelectReturnItem extends PosReturnEvent {
  final String inventarisId;
  final bool selected;
  const SelectReturnItem(this.inventarisId, this.selected);
  @override
  List<Object?> get props => [inventarisId, selected];
}

class UpdateReturnItem extends PosReturnEvent {
  final String inventarisId;
  final double qtyReturned;
  final String kondisi;
  final bool masukKeStok;
  const UpdateReturnItem({
    required this.inventarisId,
    required this.qtyReturned,
    required this.kondisi,
    required this.masukKeStok,
  });
  @override
  List<Object?> get props => [inventarisId, qtyReturned, kondisi, masukKeStok];
}

class SubmitReturn extends PosReturnEvent {
  final String alasan;
  final String metodeRefund;
  final String catatan;
  const SubmitReturn({
    required this.alasan,
    required this.metodeRefund,
    required this.catatan,
  });
  @override
  List<Object?> get props => [alasan, metodeRefund, catatan];
}

class ApproveReturn extends PosReturnEvent {
  final String id;
  const ApproveReturn(this.id);
  @override
  List<Object?> get props => [id];
}

class ProcessReturn extends PosReturnEvent {
  final String id;
  const ProcessReturn(this.id);
  @override
  List<Object?> get props => [id];
}

class DeleteReturn extends PosReturnEvent {
  final String id;
  const DeleteReturn(this.id);
  @override
  List<Object?> get props => [id];
}

class ClearReturnForm extends PosReturnEvent {}
