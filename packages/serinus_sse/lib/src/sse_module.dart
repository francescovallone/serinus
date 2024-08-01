import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus_sse/src/sse_adapter.dart';

class SseModule extends Module {
  final int? port;

  final Future<void> Function(HttpRequest)? fallback;

  SseModule({this.port, this.fallback});

  @override
  Future<Module> registerAsync(ApplicationConfig config) async {
    config.adapters[SseAdapter] ??=
        SseAdapter(port: port ?? 8081, fallback: fallback);
    return this;
  }
}
