import 'package:benchmarks/shared/serinus_benchmark.dart';
import 'package:serinus/serinus.dart';

class TestModule extends Module {
  TestModule()
      : super(
          controllers: [TestController()],
        );
}

class TestController extends Controller {
  TestController() : super('/') {
    on(Route.get('/'), (context) async => {
      'message': 'Hello, World!',
      'dateTime': DateTime.now().toIso8601String(),
    });
  }
}

class SerinusAppBenchmark extends SerinusBenchmark {
  SerinusAppBenchmark() : super(name: 'Serinus');

  SerinusApplication? app;

  @override
  Future<void> setup() async {
    app = await serinus.createApplication(
        entrypoint: TestModule(), logLevels: {LogLevel.none}, enableCompression: false);
    await app!.serve();
  }

  @override
  Future<void> teardown() async {
    await app?.close();
  }
}
