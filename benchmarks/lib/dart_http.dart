import 'dart:io';

import 'package:benchmarks/shared/serinus_benchmark.dart';

class DartHttpAppBenchmark extends SerinusBenchmark {
  DartHttpAppBenchmark() : super(name: 'Dart Raw Http');

  HttpServer? app;

  @override
  Future<void> setup() async {
    app = await HttpServer.bind(InternetAddress.anyIPv4, 3000);
    app?.listen((event) {
      event.response.write('echo!');
      event.response.close();
    });
  }

  @override
  Future<void> teardown() async {
    await app?.close(force: true);
  }
}
