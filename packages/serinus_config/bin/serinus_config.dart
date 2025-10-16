import 'package:serinus/serinus.dart';
import 'package:serinus_config/serinus_config.dart';

class TestConfig extends ParsedConfig {
  final String test;

  TestConfig(this.test);
}

class MainController extends Controller {
  MainController() : super('/') {
    on(Route.get('/'), (RequestContext context) async {
      return context.use<TestConfig>().test;
    });
  }
}

class MainModule extends Module {
  MainModule()
      : super(imports: [
        ConfigModule(
          paths: ['.env'],
          includePlatformEnvironment: false,
          factories: [
            (env) => TestConfig(env['TEST'] ?? ''),
          ]
        )
      ], controllers: [MainController()]);
}

void main() async {
  final app = await serinus.createApplication(entrypoint: MainModule());
  await app.serve();
}
