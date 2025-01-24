import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus_sse/src/sse_adapter.dart';

class SseModule extends Module {

  final Future<void> Function(HttpRequest)? fallback;

  SseModule({this.fallback});

  @override
  Future<Module> registerAsync(ApplicationConfig config) async {
    config.adapters[SseAdapter] ??=
        SseAdapter(fallback: fallback);
    return this;
  }
}
