import 'package:benchmarks/shared/serinus_benchmark.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';


class ShelfRouterAppBenchmark extends SerinusBenchmark {
  // ignore: prefer_typing_uninitialized_variables
  ShelfRouterAppBenchmark() : super(name: 'Shelf Router');

  var server;

  @override
  Future<void> setup() async {
    var router = Router();
    router.get('/', (Request request) => Response.ok('echo!'));
    server = await serve(router.call, 'localhost', 3000);
  }

  @override
  Future<void> teardown() async {
    await server.close(force: true);
  }
}
