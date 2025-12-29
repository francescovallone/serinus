import 'dart:io';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class _CollectSink implements ObserveSink {
  RequestTrace? last;
  int count = 0;

  @override
  Future<void> consume(RequestTrace trace) async {
    last = trace;
    count++;
  }
}
class MockIncomingMessage extends Mock implements IncomingMessage {
  @override
  Map<String, String> get queryParameters => {};

  @override
  String get method => 'GET';

  String get path => '/test';

  @override
  ContentType get contentType => ContentType.text;

  @override
  Future<Uint8List> bytes() {
    return Future.value(Uint8List(0));
  }
}

void main() {
  group('ObserveHandle', () {
    test('captures successful steps', () async {
      final config = ObserveConfig(enabled: true);
      final plan = config.resolveForRoute(
        routeId: 'route',
        controllerType: Object,
        method: HttpMethod.get,
      );
      final request = Request(MockIncomingMessage());
      final requestContext = await RequestContext.create<dynamic>(
        request: request,
        providers: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null,
      );
      final handle = plan.activate(requestContext)!;

      final result = handle.step('work', () => 2 + 2, phase: ObservePhase.handle);

      expect(result, 4);
      expect(handle.trace.steps, hasLength(1));
      final step = handle.trace.steps.single;
      expect(step.name, 'work');
      expect(step.phase, ObservePhase.handle);
      expect(step.success, isTrue);
      expect(step.duration, isNotNull);
    });

    test('captures failing steps', () async {
      final config = ObserveConfig(enabled: true);
      final plan = config.resolveForRoute(
        routeId: 'route',
        controllerType: Object,
        method: HttpMethod.get,
      );
      final request = Request(MockIncomingMessage());
      final requestContext = await RequestContext.create<dynamic>(
        request: request,
        providers: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null,
      );
      final handle = plan.activate(requestContext)!;

      expect(
        () => handle.step('boom', () => throw StateError('fail'), phase: ObservePhase.handle),
        throwsStateError,
      );

      expect(handle.trace.steps, hasLength(1));
      final step = handle.trace.steps.single;
      expect(step.name, 'boom');
      expect(step.phase, ObservePhase.handle);
      expect(step.success, isFalse);
      expect(step.errorRef, isA<StateError>());
    });
  });

  group('ObserveConfig', () {
    test('flush sends trace to sinks', () async {
      final sink = _CollectSink();
      final config = ObserveConfig(
        enabled: true,
        sinks: [sink],
      );
      final plan = config.resolveForRoute(
        routeId: 'test',
        controllerType: Object,
        method: HttpMethod.get,
      );
      final request = Request(MockIncomingMessage());
      final requestContext = await RequestContext.create<dynamic>(
        request: request,
        providers: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null
      );
      final executionContext = ExecutionContext(
        HostType.http,
        const {},
        const {},
        HttpArgumentsHost(request),
      );
      executionContext.attachHttpContext(requestContext);
      executionContext.observe = plan.activate(requestContext);

      await config.flush(executionContext);

      expect(sink.count, 1);
      expect(sink.last, isNotNull);
      expect(sink.last!.routeId, 'test');
    });
  });
}
