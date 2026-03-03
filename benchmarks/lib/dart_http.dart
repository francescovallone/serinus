import 'dart:io';
import 'dart:convert';

import 'package:benchmarks/shared/serinus_benchmark.dart';

class DartHttpAppBenchmark extends SerinusBenchmark {
  DartHttpAppBenchmark() : super(name: 'Dart Raw Http');

  HttpServer? app;

  @override
  Future<void> setup() async {
    app = await HttpServer.bind(InternetAddress.anyIPv4, 3000);
    app?.listen((event) {
      event.response.write(jsonEncode({
        'message': 'Hello, World!',
        'dateTime': DateTime.now().toIso8601String(),
      }));
      event.response.close();
    });
  }

  @override
  Future<void> teardown() async {
    await app?.close(force: true);
  }
}
