class PosCustomer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String priceLevel;

  const PosCustomer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    required this.priceLevel,
  });

  factory PosCustomer.fromJson(Map<String, dynamic> json) {
    return PosCustomer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email']?.toString() ?? '',
      priceLevel: json['priceLevel'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'priceLevel': priceLevel,
    };
  }
}

class PosCustomerPageResult {
  final List<PosCustomer> items;
  final int totalCount;
  final int page;
  final int limit;

  const PosCustomerPageResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.limit,
  });

  bool get hasMore => page * limit < totalCount;
}
