import 'package:dotenv/dotenv.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_config/src/config_service.dart';

/// A module that provides a [ConfigService] that can be used to access environment variables.
class ConfigModule extends Module {
  /// The path to the `.env` file.
  final String dotEnvPath;

  /// Create a new instance of [ConfigModule].
  ///
  /// Optionally, you can pass a [ConfigModuleOptions] object to configure the module.
  ConfigModule({this.dotEnvPath = '.env'}) : super(isGlobal: true);

  @override

  /// Register the [ConfigService] provider.
  ///
  /// This method will load the environment variables from the `.env` file and register the [ConfigService] provider.
  ///
  /// Optionally, you can pass a [ConfigModuleOptions] object to configure the module.
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final dotEnv = DotEnv(includePlatformEnvironment: true)..load([dotEnvPath]);
    providers = [ConfigService(dotEnv)];
    return DynamicModule(
      providers: providers,
    );
  }
}
