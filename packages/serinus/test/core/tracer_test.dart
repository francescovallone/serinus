import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class ServerTimingTracer extends Tracer {
  final Map<String, int> _timings = {};

  ServerTimingTracer() : super('ServerTimingTracer');

  @override
  Future<void> onRequestReceived(TraceEvent event, Duration delta) async {
    _timings['duration'] = delta.inMilliseconds;
  }

  @override
  Future<void> onRequest(TraceEvent event, Duration delta) async {
    _timings['duration'] = (_timings['duration'] ?? 0) + delta.inMilliseconds;
  }

  @override
  Future<void> onBeforeHandle(TraceEvent event, Duration delta) async {
    _timings['duration'] = (_timings['duration'] ?? 0) + delta.inMilliseconds;
  }

  @override
  Future<void> onHandle(TraceEvent event, Duration delta) async {
    _timings['duration'] = (_timings['duration'] ?? 0) + delta.inMilliseconds;
  }

  @override
  Future<void> onAfterHandle(TraceEvent event, Duration delta) async {
    _timings['duration'] = (_timings['duration'] ?? 0) + delta.inMilliseconds;
  }

  @override
  Future<void> onMiddleware(TraceEvent event, Duration delta) async {
    _timings['duration'] = (_timings['duration'] ?? 0) + delta.inMilliseconds;
  }

  @override
  Future<void> onParse(TraceEvent event, Duration delta) async {
    _timings['duration'] = (_timings['duration'] ?? 0) + delta.inMilliseconds;
  }

  @override
  Future<void> onResponse(TraceEvent event, Duration delta) async {
    _timings['duration'] = (_timings['duration'] ?? 0) + delta.inMilliseconds;
    event.context?.res.headers['duration'] = _timings['duration'].toString();
  }

  @override
  Future<void> onCustomEvent(TraceEvent event, Duration delta) async {
    _timings['duration'] = (_timings['duration'] ?? 0) + delta.inMilliseconds;
  }
}

class TestRoute extends Route {
  const TestRoute({
    required super.path,
    super.method = HttpMethod.get,
  });
}

class TestJsonObject with JsonObject {
  @override
  Map<String, dynamic> toJson() {
    return {'id': 'json-obj'};
  }
}

class TestController extends Controller {
  TestController([super.path = '/']) {
    on(Route.get('/'), (context) async {
      final r = trace(
        () => countTo(100),
        context: context,
        eventName: 'countTo',
      );
      final t = await traceAsync(
        () async => countTo(100),
        context: context,
        eventName: 'countTo',
      );
      return r + t;
    });
  }

  int countTo(int n) {
    return n;
  }
}

class TestMiddleware extends Middleware {
  bool hasBeenCalled = false;

  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    await Future.delayed(Duration(milliseconds: 100), () {
      hasBeenCalled = true;
    });
    next();
  }
}

class TestModule extends Module {
  TestModule({
    super.controllers,
    super.imports,
    super.providers,
    super.exports,
    super.middlewares,
  });
}

void main() {
  group('$Tracer', () {
    SerinusApplication? app;
    final controller = TestController();
    final middleware = TestMiddleware();
    setUpAll(() async {
      app = await serinus.createApplication(
          entrypoint:
              TestModule(controllers: [controller], middlewares: [middleware]),
          port: 4000,
          logLevels: {LogLevel.none});
      app?.trace(ServerTimingTracer());
      await app?.serve();
    });
    tearDownAll(() async {
      await app?.close();
    });

    test(
        'when a request is made, then the tracer should set the duration header',
        () async {
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:4000/'));
      final response = await request.close();
      expect(response.headers.value('duration'), isNotNull);
      expect(int.tryParse(response.headers.value('duration') ?? ''),
          greaterThanOrEqualTo(1));
    });
  });
}
