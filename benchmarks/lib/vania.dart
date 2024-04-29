import 'package:benchmarks/shared/serinus_benchmark.dart';
import 'package:vania/vania.dart';

class VaniaAppBenchmark extends SerinusBenchmark {
  VaniaAppBenchmark() : super(name: 'Vania');

  Application? app;

  @override
  Future<void> setup() async {
    Router.get('/', () => Response.html('echo!'));
    app = Application();
    await app?.initialize(config: {'providers': <ServiceProvider>[]});
  }

  @override
  Future<void> teardown() async {
    await app?.close();
  }
}
