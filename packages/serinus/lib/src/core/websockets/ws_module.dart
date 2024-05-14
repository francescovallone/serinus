import '../../adapters/ws_adapter.dart';
import '../../services/logger_service.dart';
import '../core.dart';

class WsModule extends Module {
  final Logger logger = Logger('WebSocket');

  @override
  Future<Module> registerAsync(ApplicationConfig config) async {
    config.wsAdapter ??= WsAdapter();
    if (!(config.wsAdapter?.isOpen ?? true)) {
      config.wsAdapter
          ?.init(Uri.tryParse('ws://${config.host}:${config.port}'));
    }
    logger.info('WebSocket Module initialized.');
    return super.registerAsync(config);
  }
}
