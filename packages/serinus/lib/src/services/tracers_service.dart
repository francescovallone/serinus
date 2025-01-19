import 'dart:async';

import '../contexts/contexts.dart';
import '../core/core.dart';
import '../core/tracer.dart';
import '../http/http.dart';

/// A service to manage tracers.
class TracersService {
  final Map<String, Tracer> _tracers = {};

  final Map<String, _TracerProperties> _properties = {};

  final StreamController<TraceEvent> _events = StreamController<TraceEvent>();

  /// Method to register a new tracer to be used.
  void registerTracer(Tracer tracer) {
    _tracers[tracer.name] = tracer;
    _events.stream.listen((event) async {
      final elapsed =
          _properties[event.request!.id]?.stopwatch.elapsed ?? Duration.zero;
      final requestElapsed =
          _properties[event.request!.id]?.lifecycleDuration.elapsed ??
              Duration.zero;
      event.requestDuration = requestElapsed;
      switch ((event.name, event.begin)) {
        case (TraceEvents.onRequestReceived, _):
          await tracer.onRequestReceived(event, elapsed);
          _properties[event.request!.id]?.completers[event.name]?.complete();
          break;
        case (TraceEvents.onRequest, false):
          await tracer.onRequest(event, elapsed);
          _properties[event.request!.id]?.completers[event.name]?.complete();
          break;
        case (TraceEvents.onParse, false):
          await tracer.onParse(event, elapsed);
          _properties[event.request!.id]?.completers[event.name]?.complete();
          break;
        case (TraceEvents.onMiddleware, false):
          await tracer.onMiddleware(event, elapsed);
          _properties[event.request!.id]?.completers[event.name]?.complete();
          break;
        case (TraceEvents.onBeforeHandle, false):
          await tracer.onBeforeHandle(event, elapsed);
          _properties[event.request!.id]?.completers[event.name]?.complete();
          break;
        case (TraceEvents.onHandle, false):
          await tracer.onHandle(event, elapsed);
          _properties[event.request!.id]?.completers[event.name]?.complete();
          break;
        case (TraceEvents.onAfterHandle, false):
          await tracer.onAfterHandle(event, elapsed);
          _properties[event.request!.id]?.completers[event.name]?.complete();
          break;
        case (TraceEvents.onResponse, false):
          await tracer.onResponse(
              event,
              _properties[event.request!.id]?.stopwatch.elapsed ??
                  Duration.zero);
          _properties[event.request!.id]?.completers[event.name]?.complete();
          _properties[event.request!.id]?.lifecycleDuration.stop();
          break;
        case (TraceEvents.onRequest, true):
        case (TraceEvents.onParse, true):
        case (TraceEvents.onMiddleware, true):
        case (TraceEvents.onBeforeHandle, true):
        case (TraceEvents.onHandle, true):
        case (TraceEvents.onAfterHandle, true):
        case (TraceEvents.onResponse, true):
          _properties[event.request!.id]?.stopwatch.reset();
          break;
      }
    });
  }

  /// Adds a new event to be traced.
  void addEvent({
    required TraceEvents name,
    required String traced,
    bool begin = false,
    RequestContext? context,
    Request? request,
  }) {
    if (_tracers.isEmpty) {
      return;
    }
    final event = TraceEvent(
        name: name,
        request: context?.request ?? request,
        begin: begin,
        context: context,
        traced: traced);
    _properties[event.request?.id]?.completers[event.name] = Completer();
    _events.add(event);
  }

  /// Adds a new event to be traced synchronously.
  Future<void> addSyncEvent({
    required TraceEvents name,
    required String traced,
    RequestContext? context,
    Request? request,
  }) async {
    if (_tracers.isEmpty) {
      return;
    }
    final event = TraceEvent(
        name: name,
        request: context?.request ?? request,
        context: context,
        traced: traced);
    if (event.name == TraceEvents.onRequestReceived) {
      _properties[event.request!.id] = _TracerProperties(
          event.request!, Stopwatch()..start(), {event.name: Completer()});
    } else if (event.name == TraceEvents.onResponse && event.begin) {
      _properties[event.request!.id]?.stopwatch.stop();
    }
    _events.add(event);
    await _properties[event.request!.id]?.completers[event.name]?.future;
    if (event.name == TraceEvents.onResponse && !event.begin) {
      _properties.remove(event.request!.id);
    }
  }
}

class _TracerProperties {
  final Request request;

  final Stopwatch stopwatch;

  Map<TraceEvents, Completer> completers;

  final Stopwatch lifecycleDuration = Stopwatch()..start();

  _TracerProperties(this.request, this.stopwatch, this.completers);
}
