import 'package:mobile_pos_pantoo/app.dart';
import 'package:mobile_pos_pantoo/bootstrap.dart';
import 'package:mobile_pos_pantoo/core/flavor/flavor_config.dart';

Future<void> main() async {
  await bootstrap(() async => const App(), flavor: FlavorConfig.production());
}
