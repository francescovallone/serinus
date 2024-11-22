import 'package:serinus/serinus.dart';

import 'app_module.dart';
import 'mustachex_view_engine.dart';

Future<void> bootstrap() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    host: 'localhost',
    port: 3000
  );
  app.viewEngine = MustacheViewEngine(viewFolder: 'views');
  await app.serve();
}
