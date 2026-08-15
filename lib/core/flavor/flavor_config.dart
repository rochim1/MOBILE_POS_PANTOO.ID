enum FlavorEnvironment { development, staging, production }

class FlavorConfig {
  final FlavorEnvironment environment;
  final String appName;

  const FlavorConfig({required this.environment, required this.appName});

  factory FlavorConfig.development() {
    return const FlavorConfig(
      environment: FlavorEnvironment.development,
      appName: 'Mobile POS Pantoo (Dev)',
    );
  }

  factory FlavorConfig.staging() {
    return const FlavorConfig(
      environment: FlavorEnvironment.staging,
      appName: 'Mobile POS Pantoo (Staging)',
    );
  }

  factory FlavorConfig.production() {
    return const FlavorConfig(
      environment: FlavorEnvironment.production,
      appName: 'Mobile POS Pantoo',
    );
  }
}
