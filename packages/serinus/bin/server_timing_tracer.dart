import 'package:serinus/serinus.dart';

class ServerTimingTracer extends Tracer {

  final Map<String, int> _timings = {};

  int get currentElapsed {
    int elapsed = 0;
    for(int time in _timings.values){
      elapsed += time;
    }
    return elapsed;
  }

  ServerTimingTracer() : super('ServerTimingTracer');

  @override
  Future<void> startTracing() async {
    _timings['startTracing'] = DateTime.now().millisecondsSinceEpoch;
    return;
  }

  @override
  Future<void> onRequest(Request request) async {
    _timings['onRequest'] = DateTime.now().millisecondsSinceEpoch - currentElapsed;
    return;
  }

  @override
  Future<void> onHandle(RequestContext context) async {
    _timings['onHandle'] = DateTime.now().millisecondsSinceEpoch - currentElapsed;
    return;
  }

  ///         label += `${event}.${i}.${name};dur=${(await end) - time},`

  @override
  Future<void> onResponse(Response response) async {
    _timings['onResponse'] = DateTime.now().millisecondsSinceEpoch - currentElapsed;

    String label = '';
    _timings.remove('startTracing');
    for(String event in _timings.keys){
      label += '$event;dur=${(_timings[event]?.isNegative ?? false) ? 0 : _timings[event]},';
    }

    response.headers['Server-Timing'] = label;
  }

}