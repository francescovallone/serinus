import 'dart:io';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class _CollectSink implements ObserveSink {
  ObserveSinkInput? last;
  int count = 0;

  @override
  Future<void> consume(ObserveSinkInput input) async {
    last = input;
    count++;
  }
}

class _FailingSink implements ObserveSink {
  @override
  Future<void> consume(ObserveSinkInput input) {
    return Future<void>.error(StateError('sink failure'));
  }
}

class _DelayedSink implements ObserveSink {
  bool completed = false;
  int count = 0;

  @override
  Future<void> consume(ObserveSinkInput input) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    completed = true;
    count++;
  }
}

class _DelayedFailingSink implements ObserveSink {
  bool attempted = false;

  @override
  Future<void> consume(ObserveSinkInput input) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    attempted = true;
    throw StateError('delayed sink failure');
  }
}

class MockSerinusHeaders extends Mock implements SerinusHeaders {
  @override
  bool containsKey(String key) {
    return false;
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
  int get contentLength => 0;

  @override
  Future<Uint8List> bytes() {
    return Future.value(Uint8List(0));
  }

  @override
  SerinusHeaders get headers => MockSerinusHeaders();
}

void main() {
  group('TraceId', () {
    test('newId generates unique values', () {
      const iterations = 1000;
      final ids = <String>{};

      for (var i = 0; i < iterations; i++) {
        ids.add(TraceId.newId().value);
      }

      expect(ids.length, iterations);
    });
  });

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
        values: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null,
      );
      final handle = plan.activate(requestContext)!;

      final result = handle.step(
        'work',
        (_) => 2 + 2,
        phase: ObservePhase.handle,
      );

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
        values: const {},
        rawBody: false,
        modelProvider: null,
      );
      final handle = plan.activate(requestContext)!;

      expect(
        () => handle.step(
          'boom',
          (_) => throw StateError('fail'),
          phase: ObservePhase.handle,
        ),
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
        appMetadata: {'env': 'test', 'service': 'serinus'},
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
        values: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null,
      );
      final executionContext = ExecutionContext(
        HostType.http,
        const {},
        const {},
        const {},
        HttpArgumentsHost(request),
      );
      executionContext.attachHttpContext(requestContext);
      executionContext.observe = plan.activate(requestContext);

      config.flush(executionContext);

      expect(sink.count, 1);
      expect(sink.last, isNotNull);
      expect(sink.last!.trace.routeId, 'test');
      expect(sink.last!.executionContext, same(executionContext));
      expect(sink.last!.appMetadata['env'], 'test');
    });

    test('flush does not throw when a sink fails', () async {
      final collectSink = _CollectSink();
      final config = ObserveConfig(
        enabled: true,
        sinks: [_FailingSink(), collectSink],
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
        values: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null,
      );
      final executionContext = ExecutionContext(
        HostType.http,
        const {},
        const {},
        const {},
        HttpArgumentsHost(request),
      );
      executionContext.attachHttpContext(requestContext);
      executionContext.observe = plan.activate(requestContext);

      await expectLater(config.flush(executionContext), completes);
      await Future<void>.delayed(Duration.zero);

      expect(collectSink.count, 1);
      expect(collectSink.last, isNotNull);
      expect(collectSink.last!.executionContext, same(executionContext));
    });

    test('flush awaits async sinks before returning', () async {
      final delayedSink = _DelayedSink();
      final config = ObserveConfig(
        enabled: true,
        sinks: [delayedSink],
      );
      final plan = config.resolveForRoute(
        routeId: 'test-await',
        controllerType: Object,
        method: HttpMethod.get,
      );
      final request = Request(MockIncomingMessage());
      final requestContext = await RequestContext.create<dynamic>(
        request: request,
        providers: const {},
        values: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null,
      );
      final executionContext = ExecutionContext(
        HostType.http,
        const {},
        const {},
        const {},
        HttpArgumentsHost(request),
      );
      executionContext.attachHttpContext(requestContext);
      executionContext.observe = plan.activate(requestContext);

      expect(delayedSink.completed, isFalse);
      await config.flush(executionContext);
      expect(delayedSink.completed, isTrue);
      expect(delayedSink.count, 1);
    });

    test('flush awaits all sinks even when some fail asynchronously', () async {
      final delayedSink = _DelayedSink();
      final delayedFailingSink = _DelayedFailingSink();
      final config = ObserveConfig(
        enabled: true,
        sinks: [delayedFailingSink, delayedSink],
      );
      final plan = config.resolveForRoute(
        routeId: 'test-await-fail',
        controllerType: Object,
        method: HttpMethod.get,
      );
      final request = Request(MockIncomingMessage());
      final requestContext = await RequestContext.create<dynamic>(
        request: request,
        providers: const {},
        values: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null,
      );
      final executionContext = ExecutionContext(
        HostType.http,
        const {},
        const {},
        const {},
        HttpArgumentsHost(request),
      );
      executionContext.attachHttpContext(requestContext);
      executionContext.observe = plan.activate(requestContext);

      await expectLater(config.flush(executionContext), completes);
      expect(delayedFailingSink.attempted, isTrue);
      expect(delayedSink.completed, isTrue);
      expect(delayedSink.count, 1);
    });
  });

  group('ObserveTracer', () {
    test('custom tracer is used by ResolvedObservePlan.activate', () async {
      final customTracer = _CustomTracer();
      final config = ObserveConfig(
        enabled: true,
        tracer: customTracer,
      );
      final plan = config.resolveForRoute(
        routeId: 'custom-route',
        controllerType: Object,
        method: HttpMethod.get,
      );
      final request = Request(MockIncomingMessage());
      final requestContext = await RequestContext.create<dynamic>(
        request: request,
        providers: const {},
        values: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null,
      );

      final handle = plan.activate(requestContext);

      expect(handle, isNotNull);
      expect(customTracer.activateCalled, isTrue);
      expect(customTracer.lastInput!.routeId, 'custom-route');
      expect(customTracer.lastInput!.method, HttpMethod.get);
      expect(handle, isA<_CustomObserveHandle>());
    });

    test('custom tracer flush is invoked by ObserveConfig.flush', () async {
      final customTracer = _CustomTracer();
      final config = ObserveConfig(
        enabled: true,
        tracer: customTracer,
      );
      final plan = config.resolveForRoute(
        routeId: 'flush-route',
        controllerType: Object,
        method: HttpMethod.post,
      );
      final request = Request(MockIncomingMessage());
      final requestContext = await RequestContext.create<dynamic>(
        request: request,
        providers: const {},
        values: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null,
      );
      final executionContext = ExecutionContext(
        HostType.http,
        const {},
        const {},
        const {},
        HttpArgumentsHost(request),
      );
      executionContext.attachHttpContext(requestContext);
      executionContext.observe = plan.activate(requestContext);

      await config.flush(executionContext);

      expect(customTracer.flushCalled, isTrue);
      expect(customTracer.flushedContext, same(executionContext));
    });

    test('custom tracer returning null skips observation', () async {
      final customTracer = _NullTracer();
      final config = ObserveConfig(
        enabled: true,
        tracer: customTracer,
      );
      final plan = config.resolveForRoute(
        routeId: 'null-route',
        controllerType: Object,
        method: HttpMethod.get,
      );
      final request = Request(MockIncomingMessage());
      final requestContext = await RequestContext.create<dynamic>(
        request: request,
        providers: const {},
        values: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null,
      );

      final handle = plan.activate(requestContext);
      expect(handle, isNull);
    });

    test('DefaultObserveTracer works like built-in behavior', () async {
      final sink = _CollectSink();
      final tracer = DefaultObserveTracer(
        sinks: [sink],
        appMetadata: {'env': 'test'},
      );
      final config = ObserveConfig(
        enabled: true,
        tracer: tracer,
      );
      final plan = config.resolveForRoute(
        routeId: 'default-tracer-route',
        controllerType: Object,
        method: HttpMethod.get,
      );
      final request = Request(MockIncomingMessage());
      final requestContext = await RequestContext.create<dynamic>(
        request: request,
        providers: const {},
        values: const {},
        hooksServices: const {},
        rawBody: false,
        modelProvider: null,
      );
      final executionContext = ExecutionContext(
        HostType.http,
        const {},
        const {},
        const {},
        HttpArgumentsHost(request),
      );
      executionContext.attachHttpContext(requestContext);
      final handle = plan.activate(requestContext);
      executionContext.observe = handle;

      expect(handle, isNotNull);
      handle!.step('test-step', (_) => 42, phase: ObservePhase.handle);

      await config.flush(executionContext);

      expect(sink.count, 1);
      expect(sink.last!.trace.routeId, 'default-tracer-route');
      expect(sink.last!.trace.steps, hasLength(1));
      expect(sink.last!.appMetadata['env'], 'test');
    });
  });
}

/// A custom tracer for testing the ObserveTracer extension point.
class _CustomTracer implements ObserveTracer {
  bool activateCalled = false;
  bool flushCalled = false;
  ObserveActivateInput? lastInput;
  ExecutionContext? flushedContext;

  @override
  ObserveHandle? activate(ObserveActivateInput input) {
    activateCalled = true;
    lastInput = input;
    final trace = RequestTrace(
      id: TraceId.newId(),
      startedAtMicros: DateTime.now().microsecondsSinceEpoch,
      routeId: input.routeId,
      path: input.requestContext.path,
      controllerType: input.controllerType,
      method: input.method,
    );
    return _CustomObserveHandle(trace);
  }

  @override
  Future<void> flush(ExecutionContext executionContext) async {
    flushCalled = true;
    flushedContext = executionContext;
  }
}

/// A tracer that always returns null (skips observation).
class _NullTracer implements ObserveTracer {
  @override
  ObserveHandle? activate(ObserveActivateInput input) => null;

  @override
  Future<void> flush(ExecutionContext executionContext) async {}
}

/// Minimal custom handle for testing.
class _CustomObserveHandle implements ObserveHandle {
  _CustomObserveHandle(this.trace);

  @override
  final RequestTrace trace;

  @override
  T step<T>(
    String name,
    T Function(ObserveStepHandle step) body, {
    ObservePhase? phase,
  }) {
    return body(_NoOpStepHandle());
  }

  @override
  Future<T> stepAsync<T>(
    String name,
    Future<T> Function(ObserveStepHandle step) body, {
    ObservePhase? phase,
  }) {
    return body(_NoOpStepHandle());
  }
}

class _NoOpStepHandle implements ObserveStepHandle {
  @override
  T step<T>(String name, T Function(ObserveStepHandle step) body) =>
      body(this);

  @override
  Future<T> stepAsync<T>(
    String name,
    Future<T> Function(ObserveStepHandle step) body,
  ) =>
      body(this);

  @override
  void recordError(Object error, [StackTrace? stackTrace]) {}

  @override
  void setAttribute(String key, Object value) {}
}
