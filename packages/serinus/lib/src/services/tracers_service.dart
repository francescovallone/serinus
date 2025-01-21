import 'dart:async';

import '../contexts/contexts.dart';
import '../core/core.dart';
import '../core/tracer.dart';
import '../http/http.dart';

/// A service to manage tracers.
class TracersService {

  static final TracersService _instance = TracersService._();

  TracersService._();

  factory TracersService() => _instance;

  final Map<String, Tracer> _tracers = {};

  final Map<Request, Map<String, TraceEvent>> _events = {};

  final Map<Request, Completer<void>> _completers = {};

  final StreamController<TraceEvent> _controller = StreamController();

  /// Method to register a new tracer to be used.
  void registerTracer(Tracer tracer) {
    _tracers[tracer.name] = tracer;
    _controller.stream.listen((event) async {
      await _callTheTracer(event, tracer);
      if(event.name == TraceEvents.onResponse.name && event.endAt != null) {
        _completers[event.request]?.complete();
      }
    });
  }

  Future<void> endTrace(Request request) async {
    if(!_completers.containsKey(request)) {
      return;
    }
    return _completers[request]!.future;
  }

  /// Adds a new event to be traced.
  void addEvent({
    required TraceEvents name,
    required String traced,
    RequestContext? context,
    Request? request,
  }) {
    if(context?.request == null && request == null) {
      throw ArgumentError('Either the RequestContext or the Request must be provided');
    }
    if (_tracers.isEmpty) {
      return;
    }
    var requestEvents = _events[context?.request ?? request];
    requestEvents ??= _events[(context?.request ?? request)!] = {};
    if(requestEvents.containsKey(name.name)) {
      final event = requestEvents[name.name]!;
      event.endAt = DateTime.now();
      _controller.add(event);
      return;
    }
    final event = TraceEvent(
        name: name.name,
        request: context?.request ?? request,
        context: context,
        traced: traced);
    if(name.name == TraceEvents.onRequestReceived.name) {
      _completers[(context?.request ?? request)!] = Completer<void>();
      event.endAt = DateTime.now();
    }
    _events[(context?.request ?? request)!]?[name.name] = event;
  }

  void addCustomEvent({
    required String name,
    required String traced,
    RequestContext? context,
    Request? request,
  }) {
    if(_tracers.isEmpty) {
      return;
    }
    var requestEvents = _events[context?.request ?? request];
    requestEvents ??= _events[(context?.request ?? request)!] = {};
    if(requestEvents.containsKey(name)) {
      final oldEvent = requestEvents[name]!;
      oldEvent.endAt = DateTime.now();
      _controller.add(oldEvent);
      requestEvents.remove(name);
      return;
    }
    final event = TraceEvent(
        name: name,
        request: context?.request ?? request,
        context: context,
        traced: traced);
    _events[(context?.request ?? request)!]?[name] = event;
  }
  
  Future<void> _callTheTracer(TraceEvent event, Tracer tracer) async {
    final delta = event.endAt?.difference(event.createdAt) ?? Duration.zero;
    if(event.name == TraceEvents.onRequestReceived.name) {
      await tracer.onRequestReceived(event, delta);
    } else if(event.name == TraceEvents.onRequest.name) {
      await tracer.onRequest(event, delta);
    } else if(event.name == TraceEvents.onBeforeHandle.name) {
      await tracer.onBeforeHandle(event, delta);
    } else if(event.name == TraceEvents.onAfterHandle.name) {
      await tracer.onAfterHandle(event, delta);
    } else if(event.name == TraceEvents.onResponse.name) {
      await tracer.onResponse(event, delta);
    } else if(event.name == TraceEvents.onParse.name) {
      await tracer.onParse(event, delta);
    } else if(event.name == TraceEvents.onMiddleware.name) {
      await tracer.onMiddleware(event, delta);
    } else if(event.name == TraceEvents.onHandle.name) {
      await tracer.onHandle(event, delta);
    } else {
      await tracer.onCustomEvent(event, delta);
    }
  }

}
