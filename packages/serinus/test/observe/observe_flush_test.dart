import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

const _testPort = 3018;

/// Sink that records all traces flushed to it, keyed by routeId.
class _RecordingSink implements ObserveSink {
  final Map<String, List<RequestTrace>> traces = {};

  @override
  Future<void> consume(ObserveSinkInput input) async {
    traces.putIfAbsent(input.trace.routeId, () => []).add(input.trace);
  }

  void reset() => traces.clear();
}

class _FlushTestExceptionFilter extends ExceptionFilter {
  const _FlushTestExceptionFilter()
    : super(catchTargets: const [BadRequestException]);

  @override
  Future<void> onException(
    ExecutionContext context,
    Exception exception,
  ) async {
    context.response.body = 'caught';
  }
}

class _FlushTestController extends Controller {
  _FlushTestController() : super('/') {
    on(Route.get('/success'), (RequestContext context) async => 'ok');
    on(Route.get('/fail'), (RequestContext context) async {
      throw BadRequestException('boom');
    });
    on(Route.post('/post-only'), (RequestContext context) async => 'posted');
  }

  @override
  Set<ExceptionFilter> get exceptionFilters => {
    const _FlushTestExceptionFilter(),
  };
}

class _FlushTestModule extends Module {
  _FlushTestModule() : super(controllers: [_FlushTestController()]);
}

void main() {
  group('Observe flush integration', () {
    late SerinusApplication app;
    final sink = _RecordingSink();

    setUpAll(() async {
      app = await serinus.createApplication(
        entrypoint: _FlushTestModule(),
        port: _testPort,
        logLevels: {LogLevel.none},
      );
      app.observe(ObserveConfig(enabled: true, sinks: [sink]));
      await app.serve();
    });

    setUp(() {
      sink.reset();
    });

    tearDownAll(() async {
      await app.close();
    });

    test('flushes trace to sink on successful request', () async {
      final request = await HttpClient().getUrl(
        Uri.parse('http://localhost:$_testPort/success'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, 200);
      expect(body, 'ok');

      // The sink should have received exactly one trace.
      final allTraces = sink.traces.values.expand((t) => t).toList();
      expect(allTraces, hasLength(1));
      expect(allTraces.first.steps, isNotEmpty);
    });

    test('flushes trace to sink on exception (route-level filter)', () async {
      final request = await HttpClient().getUrl(
        Uri.parse('http://localhost:$_testPort/fail'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, 400);
      expect(body, 'caught');

      final allTraces = sink.traces.values.expand((t) => t).toList();
      expect(allTraces, hasLength(1));
      expect(allTraces.first.steps, isNotEmpty);
    });

    test('flushes trace to sink on 404 not found', () async {
      final request = await HttpClient().getUrl(
        Uri.parse('http://localhost:$_testPort/nonexistent'),
      );
      final response = await request.close();

      expect(response.statusCode, 404);

      // The not-found path should flush a trace with routeId ::not_found.
      final notFoundTraces = sink.traces['::not_found'];
      expect(notFoundTraces, isNotNull);
      expect(notFoundTraces, hasLength(2));
    });

    test('flushes trace to sink on 405 method not allowed', () async {
      // Controller only registers GET for /post-only, so a DELETE should be 405.
      final request = await HttpClient().deleteUrl(
        Uri.parse('http://localhost:$_testPort/post-only'),
      );
      final response = await request.close();

      expect(response.statusCode, 405);

      // The method-not-allowed path should flush a trace.
      final traces = sink.traces['::method_not_allowed'];
      expect(traces, isNotNull);
      expect(traces, hasLength(2));
    });
  });
}
