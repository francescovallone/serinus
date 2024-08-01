import 'package:serinus/serinus.dart';
import 'package:serinus_config/serinus_config.dart';

class AppProvider extends Provider {
  final ConfigService _configService;

  AppProvider(this._configService);

  String sendHelloWorld() {
    return _configService.getOrThrow('TEST');
  }
}
