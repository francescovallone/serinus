import 'package:serinus/serinus.dart';

class ServerTimingTracer extends Tracer {

  final Map<String, int> _timings = {};

  ServerTimingTracer() : super('ServerTimingTracer');

  @override
  Future<void> onRequestReceived(TraceEvent event, Duration delta) async {
    _timings['${event.name.name}-${event.traced}'] = delta.inMilliseconds;
    return;
  }

  @override
  Future<void> onHandle(TraceEvent event, Duration delta) async {
    _timings['${event.name.name}-${event.traced}'] = delta.inMilliseconds;
    return;
  }

  @override
  Future<void> onAfterHandle(TraceEvent event, Duration delta) async {
    _timings['${event.name.name}-${event.traced}'] = delta.inMilliseconds;
    return;
  }

  ///         label += `${event}.${i}.${name};dur=${(await end) - time},`

  @override
  Future<void> onResponse(TraceEvent event, Duration delta) async {
    _timings['${event.name.name}-${event.traced}'] = delta.inMilliseconds;
    String label = '';
    for(String event in _timings.keys){
      label += '$event;dur=${(_timings[event]?.isNegative ?? false) ? 0 : _timings[event]},';
    }

    event.context!.res.headers['Server-Timing'] = label;
  }

}