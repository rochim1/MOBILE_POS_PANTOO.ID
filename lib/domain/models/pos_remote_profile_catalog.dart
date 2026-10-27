import 'pos_profile_catalog.dart';

class PosProfileDefinition {
  final String value, label, description, defaultOrderType;
  final bool preserveFeatures;
  final Map<String, bool> features;
  final List<Map<String, String?>> fulfillmentOptions;

  const PosProfileDefinition({
    required this.value,
    required this.label,
    required this.description,
    required this.defaultOrderType,
    required this.preserveFeatures,
    required this.features,
    required this.fulfillmentOptions,
  });

  factory PosProfileDefinition.fromJson(Map<String, dynamic> json) {
    final value = json['value']?.toString() ?? '';
    final label = json['label']?.toString() ?? '';
    if (!RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(value) ||
        label.trim().isEmpty ||
        json['features'] is! Map) {
      throw const FormatException('Profil POS tidak valid');
    }
    final flags = json['features'] as Map;
    final features = {
      for (final key in posProfilePresets['retail']!.keys)
        key: flags[key] == true,
    };
    final options = <Map<String, String?>>[];
    for (final option in json['fulfillment_options'] as List? ?? const []) {
      if (option is! Map || !_orderLabels.containsKey(option['value'])) {
        continue;
      }
      final required = option['required_feature']?.toString();
      if (required != null && !features.containsKey(required)) continue;
      options.add({
        'value': option['value'].toString(),
        'label': option['label']?.toString() ?? option['value'].toString(),
        'required_feature': required,
      });
    }
    if (!options.any((o) => o['value'] == 'take_away')) {
      throw const FormatException('Pemenuhan profil POS tidak valid');
    }
    return PosProfileDefinition(
      value: value,
      label: label,
      description: json['description']?.toString() ?? '',
      defaultOrderType: json['default_order_type']?.toString() ?? 'take_away',
      preserveFeatures: json['preserve_features'] == true,
      features: features,
      fulfillmentOptions: options,
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'label': label,
    'description': description,
    'default_order_type': defaultOrderType,
    'preserve_features': preserveFeatures,
    'features': features,
    'fulfillment_options': fulfillmentOptions,
  };
}

const _orderLabels = {
  'dine_in': 'Makan di Tempat (Pilih Meja)',
  'free_table': 'Makan di Tempat (Tanpa Meja)',
  'take_away': 'Bawa Pulang',
  'delivery': 'Pesan Antar',
  'reservation': 'Reservasi',
  'quick_service': 'Layanan Cepat',
};
const _orderRequirements = {
  'dine_in': 'use_tables',
  'delivery': 'use_delivery',
  'reservation': 'use_appointments',
};

class PosRemoteProfileCatalog {
  final String version, source;
  final List<PosProfileDefinition> profiles;
  final List<Map<String, String>> featureOptions;
  const PosRemoteProfileCatalog({
    required this.version,
    required this.source,
    required this.profiles,
    required this.featureOptions,
  });

  factory PosRemoteProfileCatalog.fromJson(
    Map<String, dynamic> json, {
    String source = 'backend',
  }) {
    final rows = json['profiles'];
    if (rows is! List || rows.isEmpty || rows.length > 100) {
      throw const FormatException('Katalog profil POS tidak valid');
    }
    final profiles = rows
        .map(
          (row) => PosProfileDefinition.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
    if (profiles.map((p) => p.value).toSet().length != profiles.length) {
      throw const FormatException('Profil POS duplikat');
    }
    final remoteFeatures = json['features'] as List? ?? const [];
    return PosRemoteProfileCatalog(
      version: json['version']?.toString() ?? '',
      source: source,
      profiles: profiles,
      featureOptions: posFeatureOptions.map((local) {
        final remote = remoteFeatures
            .whereType<Map>()
            .where((item) => item['key'] == local['key'])
            .firstOrNull;
        return {
          'key': local['key']!,
          'label': remote?['label']?.toString() ?? local['label']!,
          'description':
              remote?['description']?.toString() ?? local['description']!,
        };
      }).toList(),
    );
  }

  factory PosRemoteProfileCatalog.bundled() => PosRemoteProfileCatalog(
    version: 'bundled-v1',
    source: 'bundled',
    featureOptions: posFeatureOptions,
    profiles: posProfileIds
        .map(
          (value) => PosProfileDefinition(
            value: value,
            label: posProfileLabels[value]!,
            description: posProfileDescriptions[value]!,
            defaultOrderType: value == 'restoran' ? 'dine_in' : 'take_away',
            preserveFeatures: value == 'custom',
            features: posProfileFeatures(value),
            fulfillmentOptions:
                posFulfillmentOptions(value, {
                      for (final key in posProfilePresets['retail']!.keys)
                        key: true,
                    })
                    .map(
                      (type) => <String, String?>{
                        'value': type,
                        'label': _orderLabels[type]!,
                        'required_feature': _orderRequirements[type],
                      },
                    )
                    .toList(),
          ),
        )
        .toList(),
  );

  PosProfileDefinition? profile(String value) =>
      profiles.where((p) => p.value == value).firstOrNull;
  List<String> ids({String? current}) => [
    ...profiles.map((p) => p.value),
    if (current != null && !profiles.any((p) => p.value == current)) current,
  ];
  Map<String, bool> featuresFor(
    String value, {
    Map<String, bool> current = const {},
  }) {
    final definition = profile(value);
    return {
      ...posProfilePresets['retail']!,
      ...(definition == null || definition.preserveFeatures
          ? current
          : definition.features),
    };
  }

  List<Map<String, String?>> fulfillmentOptions(
    String value,
    Map<String, bool> features,
  ) =>
      (profile(value)?.fulfillmentOptions ??
              PosRemoteProfileCatalog.bundled()
                  .profile('retail')!
                  .fulfillmentOptions)
          .where(
            (option) =>
                option['required_feature'] == null ||
                features[option['required_feature']] == true,
          )
          .toList();
  List<String> orderTypes(String value, Map<String, bool> features) =>
      fulfillmentOptions(
        value,
        features,
      ).map((option) => option['value']!).toList();
  String defaultOrderType(
    String value,
    Map<String, bool> features, {
    String current = 'take_away',
  }) {
    final definition = profile(value);
    final requested = definition == null || definition.preserveFeatures
        ? current
        : definition.defaultOrderType;
    return orderTypes(value, features).contains(requested)
        ? requested
        : 'take_away';
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'profiles': profiles.map((p) => p.toJson()).toList(),
    'features': featureOptions,
  };
}
