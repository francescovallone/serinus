import '../contexts/contexts.dart';
import '../http/http.dart';

/// Base class for all tracers.
abstract class Tracer {
  /// The [name] of the [Tracer]
  final String name;

  /// Creates a new [Tracer] with the given [name].
  Tracer(this.name);

  /// Called to trace the onRequestReceived event
  Future<void> onRequestReceived(TraceEvent event, Duration delta) async {}

  /// Called to trace the onRequest event
  Future<void> onRequest(TraceEvent event, Duration delta) async {}

  /// Called to trace the onTransform event
  Future<void> onTranform(TraceEvent event, Duration delta) async {}

  /// Called to trace the onParse event
  Future<void> onParse(TraceEvent event, Duration delta) async {}

  /// Called to trace the onMiddleware event
  Future<void> onMiddleware(TraceEvent event, Duration delta) async {}

  /// Called to trace the onBeforeHandle event
  Future<void> onBeforeHandle(TraceEvent event, Duration delta) async {}

  /// Called to trace the onHandle event
  Future<void> onHandle(TraceEvent event, Duration delta) async {}

  /// Called to trace the onAfterHandle event
  Future<void> onAfterHandle(TraceEvent event, Duration delta) async {}

  /// Called to trace the onResponse event
  Future<void> onResponse(TraceEvent event, Duration delta) async {}
}

/// Represents a trace event.
class TraceEvent {
  /// The name of the event.
  final TraceEvents name;

  /// The context of the event.
  final RequestContext? context;

  /// The Request of the event.
  final Request? request;

  /// The timestamp of the event.
  final DateTime timestamp;

  /// Whether the event is the beginning of a cycle.
  final bool begin;

  /// The traced event.
  /// This property follows a naming convention of:
  /// - 'r-*' for route-related events (e.g. route handler, route hooks)
  /// - 'm-*' for middleware-related events
  /// - 'h-*' for hooks-related events (e.g. global hooks)
  final String traced;

  /// The duration of the lifecycle of the request.
  late final Duration requestDuration;

  /// Creates a new [TraceEvent] with the given [name], [context] and [traced].
  TraceEvent({
    required this.name,
    required this.traced,
    this.begin = false,
    this.context,
    this.request,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'TraceEvent{name: $name, context: $context, request: $request, timestamp: $timestamp, begin: $begin, traced: $traced}';
  }
}

/// Represents a trace event.
enum TraceEvents {
  /// The onRequest event.
  /// This event is triggered when a onRequest hook has been executed.
  /// Each onRequest hook has its own event.
  onRequest,

  /// The onTransform event.
  /// This event is triggered when a transform has been executed.
  onTransform,

  /// The onParse event.
  /// This event is triggered when a parse has been executed.
  onParse,

  /// The onMiddleware event.
  /// This event is triggered when a middleware has been executed.
  /// Each middleware has its own event.
  onMiddleware,

  /// The onBeforeHandle event.
  /// This event is triggered when a before handle has been executed.
  /// Each before handle has its own event.
  onBeforeHandle,

  /// The onHandle event.
  /// This event is triggered when a handle has been executed.
  /// Each handle has its own event.
  onHandle,

  /// The onAfterHandle event.
  /// This event is triggered when an after handle has been executed.
  /// Each after handle has its own event.
  onAfterHandle,

  /// The onResponse event.
  /// This event is triggered when a response has been sent.
  /// Each response has its own event.
  onResponse,

  /// The onRequestReceived event.
  /// This event is triggered when a request is received.
  /// �
  onRequestReceived
}
