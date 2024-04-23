import 'dart:io';

import 'package:benchmarks/shared/serinus_benchmark.dart';
import 'package:dart_frog/dart_frog.dart';

class DartFrogAppBenchmark extends SerinusBenchmark {

  DartFrogAppBenchmark() : super(name: 'Dart Frog');
  
  HttpServer? app;

  @override
  Future<void> setup() async {
    final handler = Pipeline().addHandler((req) => Response(body: 'echo!'));
    app = await serve(handler, 'localhost', 3000);
  }

  @override
  Future<void> teardown() async {
    await app?.close(force: true);
  }

}