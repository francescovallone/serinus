import 'package:serinus/serinus.dart';
import 'package:serinus_config/serinus_config.dart';

class MainController extends Controller {
  MainController() : super('/') {
    on(Route.get('/'), (RequestContext context) async {
      return context.use<ConfigService>().getOrThrow('TEST');
    });
  }
}

class MainModule extends Module {
  MainModule()
      : super(imports: [ConfigModule()], controllers: [MainController()]);
}

void main() async {
  final app = await serinus.createApplication(entrypoint: MainModule());
  await app.serve();
}
