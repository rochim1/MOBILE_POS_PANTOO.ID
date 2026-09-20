class PosStore {
  final String id;
  final String name;
  final String code;
  final String status;
  final String address;
  final String phone;
  final String branchName;
  final String branchId;
  final String shiftMode;

  const PosStore({
    required this.id,
    required this.name,
    this.code = '',
    required this.status,
    this.address = '',
    this.phone = '',
    this.branchName = '',
    this.branchId = '',
    this.shiftMode = 'shared_register',
  });

  factory PosStore.fromJson(Map<String, dynamic> json) {
    return PosStore(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      status: json['status'] as String,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      shiftMode: json['shiftMode'] as String? ?? 'shared_register',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'status': status,
      'address': address,
      'phone': phone,
      'branchName': branchName,
      'branchId': branchId,
      'shiftMode': shiftMode,
    };
  }
}
