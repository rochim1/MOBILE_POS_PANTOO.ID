class PosCustomer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String priceLevel;
  final String customerSegment;
  final String membershipStatus;
  final String membershipTier;
  final String customerType;

  const PosCustomer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    required this.priceLevel,
    this.customerSegment = 'regular',
    this.membershipStatus = 'non_member',
    this.membershipTier = 'regular',
    this.customerType = 'personal',
  });

  factory PosCustomer.fromJson(Map<String, dynamic> json) {
    return PosCustomer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email']?.toString() ?? '',
      priceLevel: json['priceLevel'] as String,
      customerSegment: json['customerSegment']?.toString() ?? 'regular',
      membershipStatus: json['membershipStatus']?.toString() ?? 'non_member',
      membershipTier: json['membershipTier']?.toString() ?? 'regular',
      customerType: json['customerType']?.toString() ?? 'personal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'priceLevel': priceLevel,
      'customerSegment': customerSegment,
      'membershipStatus': membershipStatus,
      'membershipTier': membershipTier,
      'customerType': customerType,
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
