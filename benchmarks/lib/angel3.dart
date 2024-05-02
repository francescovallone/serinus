import 'package:angel3_framework/angel3_framework.dart';
import 'package:angel3_framework/http.dart';
import 'package:benchmarks/shared/serinus_benchmark.dart';

class Angel3AppBenchmark extends SerinusBenchmark {
  Angel3AppBenchmark() : super(name: 'Angel3');

  var app = Angel();
  AngelHttp? http;

  @override
  Future<void> setup() async {
    app.get('/', (req, res) => 'echo!');
    http = AngelHttp(app);
    await http?.startServer('127.0.0.1', 3000);
  }

  @override
  Future<void> teardown() async {
    await http?.close();
  }
}
