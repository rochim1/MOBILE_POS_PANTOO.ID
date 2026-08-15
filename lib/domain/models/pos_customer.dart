class PosCustomer {
  final String id;
  final String name;
  final String phone;
  final String priceLevel;

  const PosCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.priceLevel,
  });

  factory PosCustomer.fromJson(Map<String, dynamic> json) {
    return PosCustomer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      priceLevel: json['priceLevel'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'phone': phone, 'priceLevel': priceLevel};
  }
}
