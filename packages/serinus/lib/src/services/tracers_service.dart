import 'dart:async';

import '../contexts/contexts.dart';
import '../core/tracer.dart';
import '../http/http.dart';

/// A service to manage tracers.
class TracersService {

  final Map<String, Tracer> _tracers = {};

  final Map<String, _TracerProperties> _properties = {};

  final StreamController<TraceEvent> _events = StreamController<TraceEvent>.broadcast();

  /// Method to register a new tracer to be used.
  void registerTracer(Tracer tracer) {
    _tracers[tracer.name] = tracer;
    _events.stream.listen((event) async {
      final elapsed = _properties[event.request!.id]?.stopwatch.elapsed ?? Duration.zero;
      final requestElapsed = _properties[event.request!.id]?.lifecycleDuration?.elapsed ?? Duration.zero;
      event.requestDuration = requestElapsed;
      print((event.name, event.begin));
      switch((event.name, event.begin)) {
        case (TraceEvents.onRequestReceived, _):
          tracer.onRequestReceived(event, elapsed);
          break;
        case (TraceEvents.onRequest, false):
          tracer.onRequest(event, elapsed);
          break;
        case (TraceEvents.onTransform, false):
          tracer.onTranform(event, elapsed);
          break;
        case (TraceEvents.onParse, false):
          tracer.onParse(event, elapsed);
          break;
        case (TraceEvents.onMiddleware, false):
          tracer.onMiddlewares(event, elapsed);
          break;
        case (TraceEvents.onBeforeHandle, false):
          tracer.onBeforeHandle(event, elapsed);
          break;
        case (TraceEvents.onHandle, false):
          tracer.onHandle(event, elapsed);
          break;
        case (TraceEvents.onAfterHandle, false):
          tracer.onAfterHandle(event, elapsed);
          break;
        case (TraceEvents.onResponse, false):
          await tracer.onResponse(event, _properties[event.request!.id]?.stopwatch.elapsed ?? Duration.zero);
          _properties[event.request!.id]?.completer.complete(true);
          _properties.remove(event.request!.id);
          break;
        case (TraceEvents.onRequest, true):
        case (TraceEvents.onParse, true):
        case (TraceEvents.onMiddleware, true):
        case (TraceEvents.onBeforeHandle, true):
        case (TraceEvents.onHandle, true):
        case (TraceEvents.onAfterHandle, true):
        case (TraceEvents.onResponse, true):
        case (TraceEvents.onTransform, true):
          _properties[event.request!.id]?.stopwatch.reset();
          break;
        default:
          break;
      }
    });
  }

  /// Adds a new event to be traced.
  void addEvent(TraceEvent event) {
    if(event.context != null) {
      _properties[event.context!.request.id]?.context = event.context;
    }
    if(event.name == TraceEvents.onRequestReceived) {
      _properties[event.request!.id] = _TracerProperties(event.request!, Stopwatch(), Completer());
    } else if(event.name == TraceEvents.onResponse && event.begin) {
      _properties[event.request!.id]?.stopwatch.stop();
    }
    _events.add(event);
  }

  /// Adds a new event to be traced synchronously.
  Future<void> addSyncEvent(TraceEvent event) {
    _events.add(event);
    return _properties[event.request!.id]?.completer.future ?? Future.value();
  }

}

class _TracerProperties {

  final Request request;

  final Stopwatch stopwatch;

  final Completer completer;

  final Stopwatch? lifecycleDuration = Stopwatch()..start();

  RequestContext? context;

  _TracerProperties(this.request, this.stopwatch, this.completer);


}