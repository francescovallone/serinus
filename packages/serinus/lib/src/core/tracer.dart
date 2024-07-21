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

  /// Called to trace the onMiddlewares event
  Future<void> onMiddlewares(TraceEvent event, Duration delta) async {}

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

  /// The duration of the request-response cycle at the time of the event.
  final Duration duration;

  /// The traced event.
  /// This property follows a naming convention of:
  /// - 'r-*' for route-related events (e.g. route handler, route hooks)
  /// - 'm-*' for middleware-related events
  /// - 'h-*' for hooks-related events (e.g. global hooks)
  final String traced;

  /// Creates a new [TraceEvent] with the given [name], [context] and [traced].
  TraceEvent({
    required this.name,
    required this.traced,
    required this.duration,
    this.context,
    this.request,
  }) : timestamp = DateTime.now();

}

/// Represents a trace event.
enum TraceEvents {

  /// The onBeginRequest event.
  /// This event is triggered when a request is received.
  onBeginRequest,

  /// The onRequest event.
  /// This event is triggered when a onRequest hook has been executed.
  /// Each onRequest hook has its own event.
  onRequest,

  /// The onBeginTransform event.
  /// This event is triggered when is going to be executed.
  onBeginTransform,

  /// The onTransform event.
  /// This event is triggered when a transform has been executed.
  onTransform,

  /// The onBeginParse event.
  /// This event is triggered when a parse is going to be executed.
  onBeginParse,

  /// The onParse event.
  /// This event is triggered when a parse has been executed.
  onParse,

  /// The onBeginMiddleware event.
  /// This event is triggered when a middleware is going to be executed.
  /// Each middleware has its own event.
  onBeginMiddleware,

  /// The onMiddleware event.
  /// This event is triggered when a middleware has been executed.
  /// Each middleware has its own event.
  onMiddleware,

  /// The onBeginBeforeHandle event.
  /// This event is triggered when a before handle is going to be executed.
  /// Each before handle has its own event.
  onBeginBeforeHandle,

  /// The onBeforeHandle event.
  /// This event is triggered when a before handle has been executed.
  /// Each before handle has its own event.
  onBeforeHandle,

  /// The onBeginHandle event.
  /// This event is triggered when a handle is going to be executed.
  /// Each handle has its own event.
  onBeginHandle,

  /// The onHandle event.
  /// This event is triggered when a handle has been executed.
  /// Each handle has its own event.
  onHandle,

  /// The onBeginAfterHandle event.
  /// This event is triggered when an after handle is going to be executed.
  /// Each after handle has its own event.
  onBeginAfterHandle,

  /// The onAfterHandle event.
  /// This event is triggered when an after handle has been executed.
  /// Each after handle has its own event.
  onAfterHandle,

  /// The onBeginResponse event.
  /// This event is triggered when a response is going to be sent.
  /// Each response has its own event.
  onBeginResponse,

  /// The onResponse event.
  /// This event is triggered when a response has been sent.
  /// Each response has its own event.
  onResponse, 
  
  /// The onRequestReceived event.
  /// This event is triggered when a request is received.
  /// �
  onRequestReceived
}