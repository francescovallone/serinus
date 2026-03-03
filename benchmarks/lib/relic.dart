import 'dart:convert';

import 'package:benchmarks/shared/serinus_benchmark.dart';
import 'package:relic/relic.dart';

class RelicAppBenchmark extends SerinusBenchmark {
  RelicAppBenchmark() : super(name: 'Relic');

  RelicApp? app;

  @override
  Future<void> setup() async {
    app = RelicApp()..get(
      '/',
      (req) => Response.ok(
        body: Body.fromString(jsonEncode({
          'message': 'Hello, World!',
          'dateTime': DateTime.now().toIso8601String(),
        })
      ),
    ));
    await app?.serve(port: 3000);
  }

  @override
  Future<void> teardown() async {
    await app?.close();
  }
}
