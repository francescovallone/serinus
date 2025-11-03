import 'package:serinus/serinus.dart';

import 'app_module.dart';
import 'mustachex_view_engine.dart';

Future<void> bootstrap() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    host: 'localhost',
    port: 3000,
    logLevels: {LogLevel.debug},
    logger: ConsoleLogger(),
  );
  app.viewEngine = MustacheViewEngine(viewFolder: 'views');
  app.use(BodySizeLimitHook());
  await app.serve();
}
