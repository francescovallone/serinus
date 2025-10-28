import '../../adapters/adapters.dart';
import '../core.dart';

/// The SSE module is responsible for managing Server-Sent Events (SSE) connections.
class SseModule extends Module {
  /// The duration for which the SSE connection should be kept alive.
  final Duration? keepAlive;

  /// The constructor for [SseModule].
  SseModule({this.keepAlive});

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final sseAdapter = SseAdapter(
      config.adapters.get<HttpAdapter>('http'),
      keepAlive: keepAlive,
    );
    config.adapters.add(sseAdapter);
    final sseRegistry = SseRegistry(config);
    final sseEmitters = SseEmitters(sseAdapter);
    return DynamicModule(imports: [sseEmitters], providers: [sseRegistry]);
  }
}

/// The SSE dispatchers are responsible for dispatching SSE events to connected clients.
class SseEmitters extends Module {
  @override
  bool get isGlobal => true;

  /// The constructor for [SseDispatchers].
  SseEmitters(SseAdapter adapter)
    : super(providers: [SseEmitter(adapter)]);
}
