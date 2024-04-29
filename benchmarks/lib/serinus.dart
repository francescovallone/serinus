import 'package:benchmarks/shared/serinus_benchmark.dart';
import 'package:serinus/serinus.dart';

class TestModule extends Module {
  TestModule()
      : super(
          controllers: [TestController()],
        );
}

class TestRoute extends Route {
  const TestRoute({
    super.path = '/',
    super.method = HttpMethod.get,
  });
}

class TestController extends Controller {
  TestController() : super(path: '/') {
    on(TestRoute(), (context) async => Response.text('echo!'));
  }
}

class SerinusAppBenchmark extends SerinusBenchmark {
  SerinusAppBenchmark() : super(name: 'Serinus');

  SerinusApplication? app;

  @override
  Future<void> setup() async {
    app = await serinus.createApplication(
        entrypoint: TestModule(), loggingLevel: LogLevel.none);
    await app!.serve();
  }

  @override
  Future<void> teardown() async {
    await app?.close();
  }
}
