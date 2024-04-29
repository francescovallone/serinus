import 'package:serinus/serinus.dart';

import 'app_module.dart';

Future<void> bootstrap() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(), host: '0.0.0.0', port: 3000);
  await app.serve();
}
