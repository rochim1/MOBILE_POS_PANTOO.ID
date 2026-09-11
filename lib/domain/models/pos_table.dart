import 'package:equatable/equatable.dart';

class PosTableModel extends Equatable {
  final String id;
  final String name;
  final String storeId;
  final int capacity;
  final String status; // Tersedia / Terisi
  final bool statusAktif;
  final String? activeOrderId;
  final String? activeOrderNo;
  final String? activeOrderStatus;
  final String? activeOrderSource;
  final String? activeCustomerName;
  final String? activeOrderCreatedAt;
  final double activeOrderTotal;
  final int activeOrderItemCount;
  final String? createdAt;
  final String? updatedAt;

  const PosTableModel({
    required this.id,
    required this.name,
    this.storeId = '',
    this.capacity = 4,
    this.status = 'Tersedia',
    this.statusAktif = true,
    this.activeOrderId,
    this.activeOrderNo,
    this.activeOrderStatus,
    this.activeOrderSource,
    this.activeCustomerName,
    this.activeOrderCreatedAt,
    this.activeOrderTotal = 0,
    this.activeOrderItemCount = 0,
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
      activeOrderId: json['active_order_id']?.toString(),
      activeOrderNo: json['active_order_no']?.toString(),
      activeOrderStatus: json['active_order_status']?.toString(),
      activeOrderSource: json['active_order_source']?.toString(),
      activeCustomerName: json['active_customer_name']?.toString(),
      activeOrderCreatedAt: json['active_order_created_at']?.toString(),
      activeOrderTotal:
          double.tryParse(json['active_order_total']?.toString() ?? '') ?? 0,
      activeOrderItemCount:
          int.tryParse(json['active_order_item_count']?.toString() ?? '') ?? 0,
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
      'active_order_id': activeOrderId,
      'active_order_no': activeOrderNo,
      'active_order_status': activeOrderStatus,
      'active_order_source': activeOrderSource,
      'active_customer_name': activeCustomerName,
      'active_order_created_at': activeOrderCreatedAt,
      'active_order_total': activeOrderTotal,
      'active_order_item_count': activeOrderItemCount,
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
    String? activeOrderId,
    String? activeOrderNo,
    String? activeOrderStatus,
    String? activeOrderSource,
    String? activeCustomerName,
    String? activeOrderCreatedAt,
    double? activeOrderTotal,
    int? activeOrderItemCount,
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
      activeOrderId: activeOrderId ?? this.activeOrderId,
      activeOrderNo: activeOrderNo ?? this.activeOrderNo,
      activeOrderStatus: activeOrderStatus ?? this.activeOrderStatus,
      activeOrderSource: activeOrderSource ?? this.activeOrderSource,
      activeCustomerName: activeCustomerName ?? this.activeCustomerName,
      activeOrderCreatedAt: activeOrderCreatedAt ?? this.activeOrderCreatedAt,
      activeOrderTotal: activeOrderTotal ?? this.activeOrderTotal,
      activeOrderItemCount: activeOrderItemCount ?? this.activeOrderItemCount,
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
    activeOrderId,
    activeOrderNo,
    activeOrderStatus,
    activeOrderSource,
    activeCustomerName,
    activeOrderCreatedAt,
    activeOrderTotal,
    activeOrderItemCount,
    createdAt,
    updatedAt,
  ];
}
