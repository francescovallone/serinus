import 'package:benchmarks/shared/serinus_benchmark.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

Response _echoRequest(Request request) => Response.ok('echo!');

class ShelfAppBenchmark extends SerinusBenchmark {
  // ignore: prefer_typing_uninitialized_variables
  ShelfAppBenchmark() : super(name: 'Shelf');

  var server;

  @override
  Future<void> setup() async {
    var handler = const Pipeline().addHandler(_echoRequest);
    server = await serve(handler, 'localhost', 3000);
  }

  @override
  Future<void> teardown() async {
    await server.close(force: true);
  }
}
