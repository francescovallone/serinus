import '../contexts/contexts.dart';
import '../contexts/request_context.dart';
import '../enums/http_method.dart';
import '../services/logger_service.dart';

/// Pipeline phases that can be observed.
enum ObservePhase {
  routing,
  requestHook,
  pipe,
  middleware,
  beforeHandle,
  handle,
  afterHandle,
  response,
  exception,
}

/// Identifier for a trace.
extension type TraceId(String value) {

  static int _seed = 0;

  /// Generates a new [TraceId] using a monotonically increasing counter.
  factory TraceId.newId() {
    _seed++;
    return TraceId('tr-${DateTime.now().microsecondsSinceEpoch}-$_seed');
  }
}

/// Represents a single observed step.
final class TraceStep {
  TraceStep({
    required this.name,
    required this.startedAtMicros,
    required this.phase,
    this.parentIndex,
  });

  /// The logical name or identifier of the step.
  final String name;

  /// Microsecond timestamp when the step started.
  final int startedAtMicros;

  /// Microsecond timestamp when the step finished.
  int? endedAtMicros;

  /// Whether the step completed successfully.
  bool success = true;

  /// Optional error reference when the step failed.
  Object? errorRef;

  /// Optional parent step index for nesting.
  final int? parentIndex;

  /// The pipeline phase associated with this step, if any.
  final ObservePhase? phase;

  /// Duration of the step if it has completed.
  Duration? get duration =>
      endedAtMicros == null ? null : Duration(microseconds: endedAtMicros! - startedAtMicros);
}

/// Aggregates all steps for a single request.
final class RequestTrace {
  RequestTrace({
    required this.id,
    required this.routeId,
    required this.path,
    required this.controllerType,
    required this.method,
  });

  final TraceId id;
  final String routeId;
  final Type controllerType;
  final String path;
  final HttpMethod method;

  /// Collected steps in execution order.
  final List<TraceStep> steps = [];
}

/// Input used for deterministic sampling decisions.
final class ObserveSamplingInput {
  ObserveSamplingInput({
    required this.routeId,
    required this.controllerType,
    required this.method,
    this.userKey,
  });

  final String routeId;
  final Type controllerType;
  final HttpMethod method;
  final String? userKey;
}

/// A deterministic sampling strategy based on hashing.
final class ObserveSampling {
  /// Modulus for hash bucketing. When set to 1, sampling always passes.
  final int modulus;

  /// Accept bucket value in range [0, modulus).
  final int acceptBucket;

  const ObserveSampling({this.modulus = 1, this.acceptBucket = 0})
      : assert(modulus > 0, 'modulus must be > 0'),
        assert(acceptBucket >= 0 && acceptBucket < modulus, 'acceptBucket must be in range');

  const ObserveSampling.always() : this(modulus: 1, acceptBucket: 0);

  bool shouldSample(ObserveSamplingInput input) {
    final h = _stableHash(input);
    return h % modulus == acceptBucket;
  }

  int _stableHash(ObserveSamplingInput input) {
    // Use Object.hashAll for a stable, fast hash across provided tokens.
    return Object.hashAll([
      input.routeId,
      input.controllerType,
      input.method,
      input.userKey,
    ]);
  }
}

/// Hook input for providing an optional user key used in sampling.
final class ObserveUserKeyInput {
  ObserveUserKeyInput(this.requestContext);

  final RequestContext requestContext;
}

/// Resolved per-route observe plan computed at startup.
final class ResolvedObservePlan {
  const ResolvedObservePlan({
    required this.enabled,
    required this.routeId,
    required this.controllerType,
    required this.method,
    required this.sampling,
    required this.phases,
    required this.stepNames,
    required this.userKeyExtractor,
  });

  const ResolvedObservePlan.disabled()
      : enabled = false,
        routeId = '',
        controllerType = Object,
        method = HttpMethod.all,
        sampling = const ObserveSampling.always(),
        phases = const {},
        stepNames = const {},
        userKeyExtractor = null;

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
    final trace = RequestTrace(
      id: TraceId.newId(),
      routeId: routeId,
      path: requestContext.path,
      controllerType: controllerType,
      method: method,
    );
    return _ActiveObserveHandle(
      trace: trace,
      phases: phases,
      stepNames: stepNames,
    );
  }
}

/// Application-level configuration for observability.
final class ObserveConfig {
  const ObserveConfig({
    this.enabled = false,
    this.sampling = const ObserveSampling.always(),
    this.controllers = const {},
    this.routes = const {},
    this.phases = const {},
    this.stepNames = const {},
    this.userKeyExtractor,
    this.sinks = const [],
  });

  const ObserveConfig.disabled() : this(enabled: false);

  /// Master enable flag. When false, observability is entirely disabled.
  final bool enabled;

  /// Sampling strategy used for all routes.
  final ObserveSampling sampling;

  /// Registered sinks for emitting traces.
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
    );
  }

  Future<void> flush(ExecutionContext executionContext) async {
    final handle = executionContext.observe;
    if (handle == null || sinks.isEmpty) {
      return;
    }
    for (final sink in sinks) {
      await sink.consume(handle.trace);
    }
  }
}

/// Public handle for observing steps. Null in disabled mode.
abstract class ObserveHandle {
  /// The accumulated trace for the current request.
  RequestTrace get trace;

  /// Runs a synchronous step with observation.
  T step<T>(String name, T Function() body, {ObservePhase? phase, int? parentIndex});

  /// Runs an asynchronous step with observation.
  Future<T> stepAsync<T>(String name, Future<T> Function() body, {ObservePhase? phase, int? parentIndex});
}

/// Sink interface for emitting observed traces to external systems.
abstract class ObserveSink {
  Future<void> consume(RequestTrace trace);
}

/// Logger-based sink for quick inspection and debugging.
final class LoggerObserveSink implements ObserveSink {
  LoggerObserveSink([Logger? logger]) : _logger = logger ?? Logger('Observability');

  final Logger _logger;

  @override
  Future<void> consume(RequestTrace trace) async {
    if (trace.steps.isEmpty) {
      _logger.info('${trace.routeId} ${trace.method} ${trace.path} (no steps recorded)');
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
  })  : _phases = phases,
        _stepNames = stepNames;

  @override
  final RequestTrace trace;

  final Set<ObservePhase> _phases;
  final Set<String> _stepNames;

  bool _shouldCapture(String name, ObservePhase? phase) {
    if (phase != null && _phases.isNotEmpty && !_phases.contains(phase)) {
      return false;
    }
    if (_stepNames.isNotEmpty && !_stepNames.contains(name)) {
      return false;
    }
    return true;
  }

  int _now() => DateTime.now().microsecondsSinceEpoch;

  @override
  T step<T>(String name, T Function() body, {ObservePhase? phase, int? parentIndex}) {
    if (!_shouldCapture(name, phase)) {
      return body();
    }
    final start = _now();
    try {
      final result = body();
      trace.steps.add(
        TraceStep(name: name, startedAtMicros: start, phase: phase, parentIndex: parentIndex)
          ..endedAtMicros = _now(),
      );
      return result;
    } catch (e) {
      trace.steps.add(
        TraceStep(name: name, startedAtMicros: start, phase: phase, parentIndex: parentIndex)
          ..success = false
          ..errorRef = e
          ..endedAtMicros = _now(),
      );
      rethrow;
    }
  }

  @override
  Future<T> stepAsync<T>(String name, Future<T> Function() body, {ObservePhase? phase, int? parentIndex}) async {
    if (!_shouldCapture(name, phase)) {
      return body();
    }
    final start = _now();
    try {
      final result = await body();
      trace.steps.add(
        TraceStep(name: name, startedAtMicros: start, phase: phase, parentIndex: parentIndex)
          ..endedAtMicros = _now(),
      );
      return result;
    } catch (e) {
      trace.steps.add(
        TraceStep(name: name, startedAtMicros: start, phase: phase, parentIndex: parentIndex)
          ..success = false
          ..errorRef = e
          ..endedAtMicros = _now(),
      );
      rethrow;
    }
  }
}
