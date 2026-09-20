import 'package:equatable/equatable.dart';

abstract class PosTableEvent extends Equatable {
  const PosTableEvent();

  @override
  List<Object?> get props => [];
}

class LoadTables extends PosTableEvent {
  final String storeId;
  final String? search;
  const LoadTables({required this.storeId, this.search});

  @override
  List<Object?> get props => [storeId, search];
}

class CreateTable extends PosTableEvent {
  final String name;
  final int capacity;
  final String area;
  final String floor;
  final String locationNote;
  const CreateTable({
    required this.name,
    this.capacity = 4,
    this.area = '',
    this.floor = '',
    this.locationNote = '',
  });

  @override
  List<Object?> get props => [name, capacity, area, floor, locationNote];
}

class UpdateTable extends PosTableEvent {
  final String id;
  final String? name;
  final int? capacity;
  final String? status;
  final String? area;
  final String? floor;
  final String? locationNote;
  const UpdateTable({
    required this.id,
    this.name,
    this.capacity,
    this.area,
    this.floor,
    this.locationNote,
    this.status,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    capacity,
    area,
    floor,
    locationNote,
    status,
  ];
}

class DeleteTable extends PosTableEvent {
  final String id;
  const DeleteTable({required this.id});

  @override
  List<Object?> get props => [id];
}

class UpdateTableStatus extends PosTableEvent {
  final String id;
  final String status;
  const UpdateTableStatus({required this.id, required this.status});

  @override
  List<Object?> get props => [id, status];
}
