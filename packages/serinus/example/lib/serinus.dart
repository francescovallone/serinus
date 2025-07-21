import 'package:serinus/serinus.dart';

import 'app_module.dart';

/// The [bootstrap] function is used to bootstrap the application.
/// This function creates an application and serves it.
Future<void> bootstrap() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(), host: '0.0.0.0', port: 4000);
  await app.serve();
}
