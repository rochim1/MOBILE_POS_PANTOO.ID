class PosPromo {
  final String id;
  final String code;
  final String name;
  final String description;
  final String discountType;
  final String valueType;
  final double discountValue;
  final double maxDiscountAmount;
  final int usageLimit;
  final int usagePerUser;
  final int currentUsageCount;
  final String startDate;
  final String endDate;
  final double minPurchaseAmount;
  final List<String> allowedChannels;
  final List<String> allowedSegments;
  final bool isActive;
  final bool isValid;
  final int remainingUsage;
  final double usagePercentage;

  const PosPromo({
    required this.id,
    required this.code,
    required this.name,
    this.description = '',
    this.discountType = 'promo',
    this.valueType = 'percentage',
    this.discountValue = 0,
    this.maxDiscountAmount = 0,
    this.usageLimit = 0,
    this.usagePerUser = 0,
    this.currentUsageCount = 0,
    this.startDate = '',
    this.endDate = '',
    this.minPurchaseAmount = 0,
    this.allowedChannels = const [],
    this.allowedSegments = const [],
    this.isActive = true,
    this.isValid = true,
    this.remainingUsage = 0,
    this.usagePercentage = 0,
  });

  factory PosPromo.fromJson(Map<String, dynamic> json) {
    return PosPromo(
      id: json['_id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'promo',
      valueType: json['value_type']?.toString() ?? 'percentage',
      discountValue:
          double.tryParse(json['discount_value']?.toString() ?? '0') ?? 0,
      maxDiscountAmount:
          double.tryParse(json['max_discount_amount']?.toString() ?? '0') ?? 0,
      usageLimit: int.tryParse(json['usage_limit']?.toString() ?? '0') ?? 0,
      usagePerUser:
          int.tryParse(json['usage_per_user']?.toString() ?? '0') ?? 0,
      currentUsageCount:
          int.tryParse(json['current_usage_count']?.toString() ?? '0') ?? 0,
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      minPurchaseAmount:
          double.tryParse(json['min_purchase_amount']?.toString() ?? '0') ?? 0,
      allowedChannels:
          (json['allowed_channels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      allowedSegments:
          (json['allowed_segments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isActive: json['is_active'] == true,
      isValid: json['is_valid'] == true,
      remainingUsage:
          int.tryParse(json['remaining_usage']?.toString() ?? '0') ?? 0,
      usagePercentage:
          double.tryParse(json['usage_percentage']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'code': code,
      'name': name,
      'description': description,
      'discount_type': discountType,
      'value_type': valueType,
      'discount_value': discountValue,
      'max_discount_amount': maxDiscountAmount,
      'usage_limit': usageLimit,
      'usage_per_user': usagePerUser,
      'current_usage_count': currentUsageCount,
      'start_date': startDate,
      'end_date': endDate,
      'min_purchase_amount': minPurchaseAmount,
      'allowed_channels': allowedChannels,
      'allowed_segments': allowedSegments,
      'is_active': isActive,
      'is_valid': isValid,
      'remaining_usage': remainingUsage,
      'usage_percentage': usagePercentage,
    };
  }
}
