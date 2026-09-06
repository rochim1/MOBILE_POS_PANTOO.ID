class PosProduct {
  final String id;
  final String code;
  final String name;
  final String category;
  final String categoryId;
  final String productType;
  final bool promoEligible;
  final bool tracksStock;
  final String description;
  final String brand;
  final double purchasePrice;
  final String purchasePriceSource;
  final List<Map<String, dynamic>> packageComponents;
  final double price;
  final double stock;
  final String sku;
  final String barcode;
  final String imageUrl;
  final String baseUnit;
  final List<Map<String, dynamic>> unitConversions;
  final double minimumStock;
  final double maximumStock;
  final double reorderPoint;
  final int procurementLeadTime;

  const PosProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.categoryId = '',
    this.productType = 'product',
    this.promoEligible = false,
    this.tracksStock = true,
    this.description = '',
    this.brand = '',
    this.purchasePrice = 0,
    this.purchasePriceSource = 'manual',
    this.packageComponents = const [],
    required this.price,
    required this.stock,
    this.sku = '',
    this.barcode = '',
    this.imageUrl = '',
    this.baseUnit = 'unit',
    this.unitConversions = const [
      {'unit': 'unit', 'factor': 1.0},
    ],
    this.minimumStock = 0,
    this.maximumStock = 0,
    this.reorderPoint = 0,
    this.procurementLeadTime = 0,
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
      categoryId:
          json['categoryId']?.toString() ??
          json['merchandise_category_id']?.toString() ??
          '',
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
      description:
          json['description']?.toString() ??
          json['deskripsi']?.toString() ??
          '',
      brand: json['brand']?.toString() ?? '',
      purchasePrice:
          double.tryParse(
            json['purchasePrice']?.toString() ??
                json['harga_beli']?.toString() ??
                '0',
          ) ??
          0,
      purchasePriceSource:
          json['purchasePriceSource']?.toString() ??
          json['harga_beli_source']?.toString() ??
          'manual',
      packageComponents:
          (json['packageComponents'] ?? json['pos_package_components']) is List
          ? ((json['packageComponents'] ?? json['pos_package_components'])
                    as List)
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .toList()
          : const [],
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
      minimumStock:
          double.tryParse(
            json['minimumStock']?.toString() ??
                json['stok_minimum']?.toString() ??
                '0',
          ) ??
          0,
      maximumStock:
          double.tryParse(
            json['maximumStock']?.toString() ??
                json['stok_maksimum']?.toString() ??
                '0',
          ) ??
          0,
      reorderPoint:
          double.tryParse(
            json['reorderPoint']?.toString() ??
                json['titik_reorder']?.toString() ??
                '0',
          ) ??
          0,
      procurementLeadTime:
          int.tryParse(
            json['procurementLeadTime']?.toString() ??
                json['lead_time_pengadaan']?.toString() ??
                '0',
          ) ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'categoryId': categoryId,
      'productType': productType,
      'promoEligible': promoEligible,
      'tracksStock': tracksStock,
      'description': description,
      'brand': brand,
      'purchasePrice': purchasePrice,
      'purchasePriceSource': purchasePriceSource,
      'packageComponents': packageComponents,
      'price': price,
      'stock': stock,
      'sku': sku,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'baseUnit': baseUnit,
      'unitConversions': unitConversions,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'reorderPoint': reorderPoint,
      'procurementLeadTime': procurementLeadTime,
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
