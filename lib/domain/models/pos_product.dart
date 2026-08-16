class PosProduct {
  final String id;
  final String code;
  final String name;
  final String category;
  final String productType;
  final bool promoEligible;
  final bool tracksStock;
  final double price;
  final double stock;
  final String sku;
  final String barcode;
  final String imageUrl;
  final String baseUnit;
  final List<Map<String, dynamic>> unitConversions;

  const PosProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.productType = 'product',
    this.promoEligible = false,
    this.tracksStock = true,
    required this.price,
    required this.stock,
    this.sku = '',
    this.barcode = '',
    this.imageUrl = '',
    this.baseUnit = 'unit',
    this.unitConversions = const [
      {'unit': 'unit', 'factor': 1.0},
    ],
  });

  String get saleUnit {
    final normalizedBaseUnit = baseUnit.trim().toLowerCase();
    return normalizedBaseUnit.isEmpty ? 'unit' : normalizedBaseUnit;
  }

  factory PosProduct.fromJson(Map<String, dynamic> json) {
    return PosProduct(
      id: json['id'] as String? ?? json['code'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      productType:
          json['productType']?.toString() ??
          json['pos_product_type']?.toString() ??
          'product',
      promoEligible:
          json['promoEligible'] == true || json['promo_eligible'] == true,
      tracksStock: json.containsKey('tracksStock')
          ? json['tracksStock'] == true
          : json.containsKey('tracks_stock')
          ? json['tracks_stock'] == true
          : !['service', 'deposit'].contains(
              json['productType']?.toString() ??
                  json['pos_product_type']?.toString() ??
                  'product',
            ),
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toDouble(),
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['foto']?.toString() ?? '',
      baseUnit:
          json['baseUnit']?.toString() ??
          json['base_unit']?.toString() ??
          json['unit']?.toString() ??
          'unit',
      unitConversions:
          (json['unitConversions'] ?? json['unit_conversions']) is List
          ? List<Map<String, dynamic>>.from(
              (json['unitConversions'] ?? json['unit_conversions']).map(
                (row) => Map<String, dynamic>.from(row as Map),
              ),
            )
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'productType': productType,
      'promoEligible': promoEligible,
      'tracksStock': tracksStock,
      'price': price,
      'stock': stock,
      'sku': sku,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'baseUnit': baseUnit,
      'unitConversions': unitConversions,
    };
  }

  bool isUnavailableForSale({required bool trackStock}) =>
      trackStock && tracksStock && stock <= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosProduct &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
