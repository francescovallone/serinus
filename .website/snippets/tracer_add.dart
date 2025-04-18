import 'package:serinus/serinus.dart';

Future<void> main() async {
  final app = await serinus.createApplication(entrypoint: AppModule());
  app.trace(ServerTimingTracer());
  await app.serve();
}