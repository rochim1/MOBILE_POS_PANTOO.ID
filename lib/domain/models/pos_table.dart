import 'package:equatable/equatable.dart';

class PosTableModel extends Equatable {
  final String id;
  final String name;
  final String storeId;
  final int capacity;
  final String status; // Tersedia / Terisi
  final bool statusAktif;
  final String? createdAt;
  final String? updatedAt;

  const PosTableModel({
    required this.id,
    required this.name,
    this.storeId = '',
    this.capacity = 4,
    this.status = 'Tersedia',
    this.statusAktif = true,
    this.createdAt,
    this.updatedAt,
  });

  factory PosTableModel.fromJson(Map<String, dynamic> json) {
    return PosTableModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      storeId: json['toko_id']?.toString() ?? '',
      capacity: int.tryParse(json['capacity']?.toString() ?? '4') ?? 4,
      status: json['status']?.toString() ?? 'Tersedia',
      statusAktif:
          json['status_aktif'] == true || json['status_aktif'] == 'active',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'toko_id': storeId,
      'capacity': capacity,
      'status': status,
      'status_aktif': statusAktif,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  PosTableModel copyWith({
    String? id,
    String? name,
    String? storeId,
    int? capacity,
    String? status,
    bool? statusAktif,
    String? createdAt,
    String? updatedAt,
  }) {
    return PosTableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      storeId: storeId ?? this.storeId,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      statusAktif: statusAktif ?? this.statusAktif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    storeId,
    capacity,
    status,
    statusAktif,
    createdAt,
    updatedAt,
  ];
}
