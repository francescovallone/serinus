import 'package:serinus/serinus.dart';
import 'package:serinus_cors/serinus_cors.dart';
import 'app_module.dart';

/// The [bootstrap] function is used to bootstrap the application.
/// This function creates an application and serves it.
Future<void> bootstrap() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(), host: '0.0.0.0', port: 3000);
  app.use(CorsHook());
  await app.serve();
}
