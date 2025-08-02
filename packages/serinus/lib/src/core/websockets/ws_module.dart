import '../../adapters/adapters.dart';
import '../../services/logger_service.dart';
import '../core.dart';
import 'websocket_registry.dart';

/// The [WsModule] class is used to create a new instance of the [Module] class.
class WsModule extends Module {
  /// The [logger] property contains the logger of the module.
  final Logger logger = Logger('WebSocket');

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final webSocketAdapter = WebSocketAdapter(config.adapters.get<HttpAdapter>('http'));
    config.adapters.add(webSocketAdapter);
    final websocketRegistry = WebsocketRegistry(config);
    return DynamicModule(
      providers: [
        websocketRegistry,
      ],
    );
  }
}
