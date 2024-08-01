import 'package:serinus/serinus.dart';
import 'package:serinus_rate_limiter/serinus_rate_limiter.dart';

class MainController extends Controller {
  MainController({super.path = '/'}) {
    on(Route.get('/'), (context) async {
      return 'Hello world';
    });
  }
}

class MainModule extends Module {
  MainModule() : super(controllers: [MainController()]);
}

void main() async {
  final app = await serinus.createApplication(entrypoint: MainModule());
  app.use(RateLimiterHook(maxRequests: 10, duration: Duration(seconds: 10)));
  await app.serve();
}
