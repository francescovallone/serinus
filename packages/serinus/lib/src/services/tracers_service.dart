import 'dart:async';

import '../core/tracer.dart';

/// A service to manage tracers.
class TracersService {

  final Map<String, Tracer> _tracers = {};

  final Map<String, Stopwatch> _stopwatches = {};

  final StreamController<TraceEvent> _events = StreamController<TraceEvent>.broadcast();

  /// Method to register a new tracer to be used.
  void registerTracer(Tracer tracer) {
    _tracers[tracer.name] = tracer;
    _events.stream.listen((event) async {
      switch(event.name) {
        case TraceEvents.onRequestReceived:
          tracer.onRequestReceived(event, _stopwatches[event.request!.id]!.elapsed);
          break;
        case TraceEvents.onRequest:
          tracer.onRequest(event, _stopwatches[event.request!.id]!.elapsed);
          break;
        case TraceEvents.onTransform:
          tracer.onTranform(event, _stopwatches[event.context!.request.id]!.elapsed);
          break;
        case TraceEvents.onParse:
          tracer.onParse(event, _stopwatches[event.context!.request.id]!.elapsed);
          break;
        case TraceEvents.onMiddleware:
          tracer.onMiddlewares(event, _stopwatches[event.context!.request.id]!.elapsed);
          break;
        case TraceEvents.onBeforeHandle:
          tracer.onBeforeHandle(event, _stopwatches[event.context!.request.id]!.elapsed);
          break;
        case TraceEvents.onHandle:
          tracer.onHandle(event, _stopwatches[event.context!.request.id]!.elapsed);
          break;
        case TraceEvents.onAfterHandle:
          tracer.onAfterHandle(event, _stopwatches[event.context!.request.id]!.elapsed);
          break;
        case TraceEvents.onResponse:
          tracer.onResponse(event, _stopwatches[event.context!.request.id]?.elapsed ?? Duration.zero);
          _stopwatches.remove(event.context!.request.id);
          break;
        case TraceEvents.onBeginRequest:
        case TraceEvents.onBeginParse:
        case TraceEvents.onBeginMiddleware:
        case TraceEvents.onBeginBeforeHandle:
        case TraceEvents.onBeginHandle:
        case TraceEvents.onBeginAfterHandle:
        case TraceEvents.onBeginResponse:
        case TraceEvents.onBeginTransform:
          _stopwatches[event.context?.request.id ?? event.request!.id]?.reset();
          break;
        default:
          break;
      }
    });
  }

  /// Adds a new event to be traced.
  void addEvent(TraceEvent event) {
    if(event.name == TraceEvents.onRequestReceived) {
      _stopwatches.putIfAbsent(event.request!.id, () => Stopwatch()..start());
    } else if(event.name == TraceEvents.onBeginResponse) {
      _stopwatches[event.context?.request.id ?? event.request?.id]?.stop();
    }
    _events.add(event);
  }

}