class PosCustomer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String note;
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
    this.address = '',
    this.note = '',
    required this.priceLevel,
    this.customerSegment = 'regular',
    this.membershipStatus = 'non_member',
    this.membershipTier = 'regular',
    this.customerType = 'personal',
  });

  factory PosCustomer.fromJson(Map<String, dynamic> json) {
    return PosCustomer(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: json['name']?.toString() ?? 'Pelanggan',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      note: (json['note'] ?? json['catatan'])?.toString() ?? '',
      priceLevel:
          (json['priceLevel'] ?? json['price_level'])?.toString() ?? 'retail',
      customerSegment:
          (json['customerSegment'] ?? json['customer_segment'])?.toString() ??
          'regular',
      membershipStatus:
          (json['membershipStatus'] ?? json['membership_status'])?.toString() ??
          'non_member',
      membershipTier:
          (json['membershipTier'] ?? json['membership_tier'])?.toString() ??
          'regular',
      customerType:
          (json['customerType'] ?? json['customer_type'])?.toString() ??
          'personal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'catatan': note,
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
