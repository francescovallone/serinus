import 'package:serinus/serinus.dart';
import 'package:serinus_serve_static/serinus_serve_static.dart';

class AppModule extends Module {
  AppModule() : super(imports: [ServeStaticModule(
    exclude: ['/text']
  )]);
}

Future<void> main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
  );
  await app.serve();
}
