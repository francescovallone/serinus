import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../contexts/contexts.dart';
import '../enums/http_method.dart';
import '../services/logger_service.dart';

final Logger _observeLogger = Logger('Observability');

/// Pipeline phases that can be observed.
enum ObservePhase {
  /// Initial routing and parameter parsing.
  routing,

  /// Request hooks
  requestHook,

  /// Pipes execution
  pipe,

  /// Middleware execution
  middleware,

  /// Before handler hooks execution
  beforeHandle,

  /// Handler execution
  handle,

  /// After handler hooks execution
  afterHandle,

  /// response hooks execution
  response,

  /// exception filters execution
  exception,
}

/// Identifier for a trace.
extension type TraceId(String value) {
  /// Generates a new [TraceId] using timestamp + secure random entropy.
  factory TraceId.newId() {
    return TraceId.fromTimestampMicros(DateTime.now().microsecondsSinceEpoch);
  }

  /// Generates a [TraceId] with the given timestamp and random entropy.
  factory TraceId.fromTimestampMicros(int timestampMicros) {
    final random = Random.secure();
    final entropy =
        '${random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0')}'
        '${random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0')}';
    return TraceId('tr-$timestampMicros-$entropy');
  }
}

/// Represents a single observed step.
final class TraceStep {
  /// Creates a [TraceStep] with the given parameters.
  TraceStep({
    required this.name,
    required this.startedAtMicros,
    required this.phase,
    this.parentIndex,
  });

  /// The logical name or identifier of the step.
  final String name;

  /// Microsecond timestamp when the step started.
  ///
  /// This value is relative to [RequestTrace.startedAtMicros].
  final int startedAtMicros;

  /// Microsecond timestamp when the step finished.
  ///
  /// This value is relative to [RequestTrace.startedAtMicros].
  int? endedAtMicros;

  /// Whether the step completed successfully.
  bool success = true;

  /// Optional error reference when the step failed.
  Object? errorRef;

  /// Optional stack trace captured alongside [errorRef].
  StackTrace? errorStackTrace;

  /// W3C-compliant attributes attached to this step (e.g. 'http.status_code').
  final Map<String, Object> attributes = {};

  /// Optional parent step index for nesting.
  final int? parentIndex;

  /// The pipeline phase associated with this step, if any.
  final ObservePhase? phase;

  /// Duration of the step if it has completed.
  Duration? get duration => endedAtMicros == null
      ? null
      : Duration(microseconds: endedAtMicros! - startedAtMicros);
}

/// Aggregates all steps for a single request.
final class RequestTrace {
  /// Creates a [RequestTrace] with the given parameters.
  RequestTrace({
    required this.id,
    required this.startedAtMicros,
    required this.routeId,
    required this.path,
    required this.controllerType,
    required this.method,
    this.maxSteps = 500,
  });

  /// Unique identifier for the trace.
  final TraceId id;

  /// Absolute wall-clock start time for this trace.
  final int startedAtMicros;

  /// The route identifier for the request.
  final String routeId;

  /// The controller type handling the request.
  final Type controllerType;

  /// The request path
  final String path;

  /// The HTTP method for the request.
  final HttpMethod method;

  /// Maximum number of steps to record before truncating.
  final int maxSteps;

  /// Collected steps in execution order.
  final List<TraceStep> steps = [];
}

/// Input used for deterministic sampling decisions.
final class ObserveSamplingInput {
  /// Creates an [ObserveSamplingInput] with the given parameters.
  ObserveSamplingInput({
    required this.routeId,
    required this.controllerType,
    required this.method,
    this.userKey,
  });

  /// The route identifier for the request.
  final String routeId;

  /// The controller type handling the request.
  final Type controllerType;

  /// The HTTP method for the request.
  final HttpMethod method;

  /// Optional user key for finer-grained sampling control.
  final String? userKey;
}

/// A deterministic sampling strategy based on hashing.
final class ObserveSampling {
  /// Modulus for hash bucketing. When set to 1, sampling always passes.
  final int modulus;

  /// Accept bucket value in range [0, modulus).
  final int acceptBucket;

  /// Creates an [ObserveSampling] with the given parameters.
  const ObserveSampling({this.modulus = 1, this.acceptBucket = 0})
    : assert(modulus > 0, 'modulus must be > 0'),
      assert(
        acceptBucket >= 0 && acceptBucket < modulus,
        'acceptBucket must be in range',
      );

  /// A convenient constant for always sampling.
  const ObserveSampling.always() : this(modulus: 1, acceptBucket: 0);

  /// Determines whether a given input should be sampled based on hashing.
  bool shouldSample(ObserveSamplingInput input) {
    final h = _stableHash(input);
    return h % modulus == acceptBucket;
  }

  int _stableHash(ObserveSamplingInput input) {
    // Use Jenkins one-at-a-time hash over canonical string tokens.
    // This is deterministic across process restarts and VM versions.
    const mask32 = 0xFFFFFFFF;
    var hash = 0;

    void mix(String token) {
      for (final byte in utf8.encode(token)) {
        hash = (hash + byte) & mask32;
        hash = (hash + ((hash << 10) & mask32)) & mask32;
        hash ^= hash >> 6;
      }
      hash = (hash + 1) & mask32;
    }

    mix(input.routeId);
    mix(input.controllerType.toString());
    mix(input.method.name);
    mix(input.userKey ?? '');

    hash = (hash + ((hash << 3) & mask32)) & mask32;
    hash ^= hash >> 11;
    hash = (hash + ((hash << 15) & mask32)) & mask32;
    return hash & mask32;
  }
}

/// Hook input for providing an optional user key used in sampling.
final class ObserveUserKeyInput {
  /// Creates an [ObserveUserKeyInput] with the given [RequestContext].
  ObserveUserKeyInput(this.requestContext);

  /// The request context for the current request, which can be used to extract
  final RequestContext requestContext;
}

/// Strategy interface for creating observe handles and flushing traces.
///
/// Implement this to integrate custom tracing backends (e.g., OpenTelemetry).
/// The default built-in implementation is [DefaultObserveTracer], which uses
/// [RequestTrace]/[TraceStep] and dispatches to [ObserveSink]s.
///
/// Example for OpenTelemetry:
/// ```dart
/// class OTelTracer implements ObserveTracer {
///   final otel.Tracer _tracer;
///   OTelTracer(this._tracer);
///
///   @override
///   ObserveHandle? activate(ObserveActivateInput input) {
///     final span = _tracer.startSpan(input.routeId);
///     return OTelObserveHandle(span, input);
///   }
///
///   @override
///   Future<void> flush(ExecutionContext context) async {
///     // End the root span, export, etc.
///   }
/// }
/// ```
abstract class ObserveTracer {
  /// Creates an [ObserveHandle] for a sampled request.
  ///
  /// Return `null` to skip observation for this request.
  /// The [input] contains all resolved route metadata and the request context.
  ObserveHandle? activate(ObserveActivateInput input);

  /// Called after request completion to finalize and export the trace.
  ///
  /// Implementations should be resilient to errors and never throw.
  Future<void> flush(ExecutionContext executionContext);
}

/// Input provided to [ObserveTracer.activate] with all resolved route metadata.
final class ObserveActivateInput {
  /// Creates an [ObserveActivateInput] with the given parameters.
  const ObserveActivateInput({
    required this.requestContext,
    required this.routeId,
    required this.controllerType,
    required this.method,
    required this.phases,
    required this.stepNames,
  });

  /// The request context for the current request.
  final RequestContext requestContext;

  /// The route identifier.
  final String routeId;

  /// The controller type handling the route.
  final Type controllerType;

  /// The HTTP method for the route.
  final HttpMethod method;

  /// Phases enabled for observation; empty set means all phases.
  final Set<ObservePhase> phases;

  /// Step names to collect; empty set means all steps.
  final Set<String> stepNames;
}

/// Default tracer implementation that uses [RequestTrace]/[TraceStep] and
/// dispatches to [ObserveSink]s.
///
/// This is the built-in tracer used when no custom [ObserveTracer] is provided
/// to [ObserveConfig].
final class DefaultObserveTracer implements ObserveTracer {
  /// Creates a [DefaultObserveTracer] with the given sinks and metadata.
  const DefaultObserveTracer({
    this.sinks = const [],
    this.appMetadata = const {},
  });

  /// Registered sinks for emitting traces.
  final List<ObserveSink> sinks;

  /// Application-level metadata propagated to sinks.
  final Map<String, Object?> appMetadata;

  @override
  ObserveHandle? activate(ObserveActivateInput input) {
    final traceStartedAtMicros = DateTime.now().microsecondsSinceEpoch;
    final trace = RequestTrace(
      id: TraceId.fromTimestampMicros(traceStartedAtMicros),
      startedAtMicros: traceStartedAtMicros,
      routeId: input.routeId,
      path: input.requestContext.path,
      controllerType: input.controllerType,
      method: input.method,
    );
    return _ActiveObserveHandle(
      trace: trace,
      phases: input.phases,
      stepNames: input.stepNames,
      stopwatch: Stopwatch()..start(),
    );
  }

  @override
  Future<void> flush(ExecutionContext executionContext) async {
    final handle = executionContext.observe;
    if (handle == null || sinks.isEmpty) {
      return;
    }
    final sinkInput = ObserveSinkInput(
      trace: handle.trace,
      executionContext: executionContext,
      appMetadata: appMetadata,
    );
    final futures = <Future<void>>[];
    for (final sink in sinks) {
      try {
        futures.add(
          sink.consume(sinkInput).catchError((Object error, StackTrace stack) {
            _observeLogger.warning(
              'Observe sink ${sink.runtimeType} failed while consuming trace ${sinkInput.trace.id.value}',
              OptionalParameters(error: error, stackTrace: stack),
            );
          }),
        );
      } catch (error, stack) {
        _observeLogger.warning(
          'Observe sink ${sink.runtimeType} threw synchronously while consuming trace ${sinkInput.trace.id.value}',
          OptionalParameters(error: error, stackTrace: stack),
        );
      }
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }
}

/// Resolved per-route observe plan computed at startup.
final class ResolvedObservePlan {
  /// Creates a [ResolvedObservePlan] with the given parameters.
  const ResolvedObservePlan({
    required this.enabled,
    required this.routeId,
    required this.controllerType,
    required this.method,
    required this.sampling,
    required this.phases,
    required this.stepNames,
    required this.userKeyExtractor,
    this.tracer,
  });

  /// Disabled plan for quick checks.
  const ResolvedObservePlan.disabled()
    : enabled = false,
      routeId = '',
      controllerType = Object,
      method = HttpMethod.all,
      sampling = const ObserveSampling.always(),
      phases = const {},
      stepNames = const {},
      userKeyExtractor = null,
      tracer = null;

  /// Whether observation is enabled for the route.
  final bool enabled;

  /// The route identifier.
  final String routeId;

  /// The controller type handling the route.
  final Type controllerType;

  /// The HTTP method for the route.
  final HttpMethod method;

  /// Sampling strategy.
  final ObserveSampling sampling;

  /// Phases enabled for observation; empty set means all phases.
  final Set<ObservePhase> phases;

  /// Step names to collect; empty set means all steps.
  final Set<String> stepNames;

  /// Optional hook to produce a user key from the request.
  final String? Function(ObserveUserKeyInput input)? userKeyExtractor;

  /// Optional custom tracer. When set, [activate] delegates to it.
  final ObserveTracer? tracer;

  /// Attempts to create an [ObserveHandle] for a given request context.
  ObserveHandle? activate(RequestContext requestContext) {
    if (!enabled) {
      return null;
    }
    final input = ObserveSamplingInput(
      routeId: routeId,
      controllerType: controllerType,
      method: method,
      userKey: userKeyExtractor?.call(ObserveUserKeyInput(requestContext)),
    );
    if (!sampling.shouldSample(input)) {
      return null;
    }
    final activateInput = ObserveActivateInput(
      requestContext: requestContext,
      routeId: routeId,
      controllerType: controllerType,
      method: method,
      phases: phases,
      stepNames: stepNames,
    );
    if (tracer != null) {
      return tracer!.activate(activateInput);
    }
    // Built-in default when no tracer is provided.
    final traceStartedAtMicros = DateTime.now().microsecondsSinceEpoch;
    final trace = RequestTrace(
      id: TraceId.fromTimestampMicros(traceStartedAtMicros),
      startedAtMicros: traceStartedAtMicros,
      routeId: routeId,
      path: requestContext.path,
      controllerType: controllerType,
      method: method,
    );
    return _ActiveObserveHandle(
      trace: trace,
      phases: phases,
      stepNames: stepNames,
      stopwatch: Stopwatch()..start(),
    );
  }
}

/// Application-level configuration for observability.
///
/// To use the built-in tracing with sinks, pass [sinks] directly:
/// ```dart
/// app.observe(ObserveConfig(
///   enabled: true,
///   sinks: [LoggerObserveSink()],
/// ));
/// ```
///
/// To integrate a custom tracing backend (e.g., OpenTelemetry), provide
/// a [tracer] instead of (or alongside) sinks:
/// ```dart
/// app.observe(ObserveConfig(
///   enabled: true,
///   tracer: OTelTracer(openTelemetry.tracer),
/// ));
/// ```
final class ObserveConfig {
  /// Creates an [ObserveConfig] with the given parameters.
  ///
  /// When [tracer] is provided, it takes ownership of handle creation and
  /// flushing. When omitted, a [DefaultObserveTracer] using [sinks] and
  /// [appMetadata] is created automatically.
  const ObserveConfig({
    this.enabled = false,
    this.sampling = const ObserveSampling.always(),
    this.controllers = const {},
    this.routes = const {},
    this.phases = const {},
    this.stepNames = const {},
    this.userKeyExtractor,
    this.appMetadata = const {},
    this.sinks = const [],
    this.tracer,
  });

  /// Disabled configuration for quick checks.
  const ObserveConfig.disabled() : this(enabled: false);

  /// Master enable flag. When false, observability is entirely disabled.
  final bool enabled;

  /// Sampling strategy used for all routes.
  final ObserveSampling sampling;

  /// Registered sinks for emitting traces (used by [DefaultObserveTracer]).
  ///
  /// Ignored when a custom [tracer] is provided.
  final List<ObserveSink> sinks;

  /// Limit observation to the given controllers, if non-empty.
  final Set<Type> controllers;

  /// Limit observation to the given route ids, if non-empty.
  final Set<String> routes;

  /// Limit observation to the given phases, if non-empty.
  final Set<ObservePhase> phases;

  /// Limit observation to the given step names, if non-empty.
  final Set<String> stepNames;

  /// Optional hook to produce a user key per request.
  final String? Function(ObserveUserKeyInput input)? userKeyExtractor;

  /// Application-level metadata propagated to sinks.
  ///
  /// This can include values like environment, hostname, version, or any other
  /// static metadata required by APM integrations.
  final Map<String, Object?> appMetadata;

  /// Optional custom tracer for full control over handle creation and flushing.
  ///
  /// When provided, [ResolvedObservePlan.activate] delegates to
  /// [ObserveTracer.activate] and [flush] delegates to [ObserveTracer.flush].
  /// This is the primary extension point for integrating backends like
  /// OpenTelemetry.
  final ObserveTracer? tracer;

  /// The effective tracer — either the user-supplied one or
  /// a [DefaultObserveTracer] built from [sinks]/[appMetadata].
  ObserveTracer get _effectiveTracer =>
      tracer ?? DefaultObserveTracer(sinks: sinks, appMetadata: appMetadata);

  /// Resolves a per-route plan at startup.
  ResolvedObservePlan resolveForRoute({
    required String routeId,
    required Type controllerType,
    required HttpMethod method,
  }) {
    if (!enabled) {
      return const ResolvedObservePlan.disabled();
    }
    if (controllers.isNotEmpty && !controllers.contains(controllerType)) {
      return const ResolvedObservePlan.disabled();
    }
    if (routes.isNotEmpty && !routes.contains(routeId)) {
      return const ResolvedObservePlan.disabled();
    }
    final phaseSet = phases.isEmpty
        ? <ObservePhase>{}
        : Set<ObservePhase>.unmodifiable(phases);
    final stepSet = stepNames.isEmpty
        ? <String>{}
        : Set<String>.unmodifiable(stepNames);
    return ResolvedObservePlan(
      enabled: true,
      routeId: routeId,
      controllerType: controllerType,
      method: method,
      sampling: sampling,
      phases: phaseSet,
      stepNames: stepSet,
      userKeyExtractor: userKeyExtractor,
      tracer: tracer,
    );
  }

  /// Flushes the trace from the execution context.
  ///
  /// When a custom [tracer] is provided, delegates entirely to
  /// [ObserveTracer.flush]. Otherwise uses [DefaultObserveTracer] to
  /// dispatch to [sinks].
  Future<void> flush(ExecutionContext executionContext) {
    return _effectiveTracer.flush(executionContext);
  }
}

/// Public handle for observing steps. Null in disabled mode.
abstract class ObserveHandle {
  /// The trace being collected for the current request.
  RequestTrace get trace;

  /// Observe a synchronous step with an optional phase and parent index.
  T step<T>(
    String name,
    T Function(ObserveStepHandle step) body, {
    ObservePhase? phase,
  });

  /// Observe an asynchronous step with an optional phase and parent index.
  Future<T> stepAsync<T>(
    String name,
    Future<T> Function(ObserveStepHandle step) body, {
    ObservePhase? phase,
  });
}

/// A handle specifically tied to a parent step
abstract class ObserveStepHandle {

  /// Allows adding W3C compliant attributes (e.g., 'http.status_code', 'http.method')
  void setAttribute(String key, Object value);

  /// Allows explicit error recording inside a span
  void recordError(Object error, [StackTrace? stackTrace]);

  /// Observe a nested synchronous step with an optional phase.
  T step<T>(String name, T Function(ObserveStepHandle step) body);

  /// Observe a nested asynchronous step with an optional phase.
  Future<T> stepAsync<T>(
    String name,
    Future<T> Function(ObserveStepHandle step) body,
  );
}

/// Sink interface for emitting observed traces to external systems.
final class ObserveSinkInput {
  /// Creates an [ObserveSinkInput] with trace and execution metadata.
  const ObserveSinkInput({
    required this.trace,
    required this.executionContext,
    required this.appMetadata,
  });

  /// The collected request trace.
  final RequestTrace trace;

  /// The execution context for this request.
  final ExecutionContext executionContext;

  /// Application-level metadata configured in [ObserveConfig].
  final Map<String, Object?> appMetadata;
}

/// Sink interface for emitting observed traces to external systems.
abstract class ObserveSink {
  /// Consumes a completed [ObserveSinkInput]. Implementations should never throw.
  Future<void> consume(ObserveSinkInput input);
}

/// Logger-based sink for quick inspection and debugging.
final class LoggerObserveSink implements ObserveSink {
  /// If no logger is provided, a default one with name 'Observability' is used.
  LoggerObserveSink([Logger? logger])
    : _logger = logger ?? Logger('Observability');

  final Logger _logger;

  @override
  Future<void> consume(ObserveSinkInput input) async {
    final trace = input.trace;
    if (trace.steps.isEmpty) {
      _logger.info(
        '${trace.routeId} ${trace.method} ${trace.path} (no steps recorded)',
      );
      return;
    }
    for (final step in trace.steps) {
      _logger.info(
        '${trace.routeId} ${trace.method} ${step.name}\n'
        'success=${step.success}\n'
        'path=${trace.path}\n'
        'duration=${step.duration?.inMicroseconds ?? 0}µs\n'
        'error=${step.errorRef}',
      );
    }
  }
}

class _ActiveObserveHandle implements ObserveHandle {
  _ActiveObserveHandle({
    required this.trace,
    required Set<ObservePhase> phases,
    required Set<String> stepNames,
    required Stopwatch stopwatch,
  }) : _phases = phases,
       _stepNames = stepNames,
       _stopwatch = stopwatch;

  @override
  final RequestTrace trace;

  final Set<ObservePhase> _phases;
  final Set<String> _stepNames;
  final Stopwatch _stopwatch;

  bool _shouldCapture(String name, ObservePhase? phase) {
    if (phase != null && _phases.isNotEmpty && !_phases.contains(phase)) {
      return false;
    }
    if (_stepNames.isNotEmpty && !_stepNames.contains(name)) {
      return false;
    }
    return true;
  }

  int _now() => _stopwatch.elapsedMicroseconds;

  ObserveStepHandle _childHandle(int? parentIndex) =>
      _ObserveChildStepHandle(this, parentIndex);

  void _recordTruncated({ObservePhase? phase, int? parentIndex}) {
    if (trace.steps.isNotEmpty && trace.steps.last.name == 'TRUNCATED') {
      return;
    }
    final startedAtMicros = trace.steps.isEmpty
        ? _now()
        : trace.steps.last.startedAtMicros;
    trace.steps.add(
      TraceStep(
        name: 'TRUNCATED',
        startedAtMicros: startedAtMicros,
        phase: phase,
        parentIndex: parentIndex,
      )..endedAtMicros = _now(),
    );
  }

  @override
  T step<T>(
    String name,
    T Function(ObserveStepHandle step) body, {
    ObservePhase? phase,
    int? parentIndex,
  }) {
    final passthroughHandle = _childHandle(parentIndex);
    if (!_shouldCapture(name, phase)) {
      return body(passthroughHandle);
    }
    if (trace.steps.length >= trace.maxSteps) {
      _recordTruncated(phase: phase, parentIndex: parentIndex);
      return body(passthroughHandle);
    }

    final start = _now();
    final step = TraceStep(
      name: name,
      startedAtMicros: start,
      phase: phase,
      parentIndex: parentIndex,
    );
    trace.steps.add(step);
    final currentIndex = trace.steps.length - 1;
    final handle = _childHandle(currentIndex);

    try {
      final result = body(handle);
      step.endedAtMicros = _now();
      return result;
    } catch (e) {
      step
        ..success = false
        ..errorRef = e
        ..endedAtMicros = _now();
      rethrow;
    }
  }

  @override
  Future<T> stepAsync<T>(
    String name,
    Future<T> Function(ObserveStepHandle step) body, {
    ObservePhase? phase,
    int? parentIndex,
  }) async {
    final passthroughHandle = _childHandle(parentIndex);
    if (!_shouldCapture(name, phase)) {
      return body(passthroughHandle);
    }
    if (trace.steps.length >= trace.maxSteps) {
      _recordTruncated(phase: phase, parentIndex: parentIndex);
      return body(passthroughHandle);
    }

    final start = _now();
    final step = TraceStep(
      name: name,
      startedAtMicros: start,
      phase: phase,
      parentIndex: parentIndex,
    );
    trace.steps.add(step);
    final currentIndex = trace.steps.length - 1;
    final handle = _childHandle(currentIndex);

    try {
      final result = await body(handle);
      step.endedAtMicros = _now();
      return result;
    } catch (e) {
      step
        ..success = false
        ..errorRef = e
        ..endedAtMicros = _now();
      rethrow;
    }
  }
}

final class _ObserveChildStepHandle implements ObserveStepHandle {
  _ObserveChildStepHandle(this._observeHandle, this._parentIndex);

  final _ActiveObserveHandle _observeHandle;
  final int? _parentIndex;

  @override
  T step<T>(String name, T Function(ObserveStepHandle step) body) {
    return _observeHandle.step(name, body, parentIndex: _parentIndex);
  }

  @override
  Future<T> stepAsync<T>(
    String name,
    Future<T> Function(ObserveStepHandle step) body,
  ) {
    return _observeHandle.stepAsync(name, body, parentIndex: _parentIndex);
  }
  
  @override
  void recordError(Object error, [StackTrace? stackTrace]) {
    final index = _parentIndex;
    if (index == null) {
      return;
    }
    final steps = _observeHandle.trace.steps;
    if (index < 0 || index >= steps.length) {
      return;
    }
    final step = steps[index];
    step
      ..success = false
      ..errorRef = error
      ..errorStackTrace = stackTrace;
  }

  @override
  void setAttribute(String key, Object value) {
    final index = _parentIndex;
    if (index == null) {
      return;
    }
    final steps = _observeHandle.trace.steps;
    if (index < 0 || index >= steps.length) {
      return;
    }
    steps[index].attributes[key] = value;
  }
}
