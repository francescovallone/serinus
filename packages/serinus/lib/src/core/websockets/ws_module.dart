import '../../adapters/ws_adapter.dart';
import '../core.dart';

class WsModule extends Module {
  @override
  Future<Module> registerAsync(ApplicationConfig config) async {
    config.wsAdapter ??= WsAdapter();
    if (!(config.wsAdapter?.isOpen ?? true)) {
      config.wsAdapter
          ?.init(Uri.tryParse('ws://${config.host}:${config.port}'));
    }
    return super.registerAsync(config);
  }
}
