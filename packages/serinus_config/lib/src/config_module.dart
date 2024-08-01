import 'package:dotenv/dotenv.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_config/src/config_service.dart';

/// A module that provides a [ConfigService] that can be used to access environment variables.
class ConfigModule extends Module {
  /// Create a new instance of [ConfigModule].
  ///
  /// Optionally, you can pass a [ConfigModuleOptions] object to configure the module.
  ConfigModule({ConfigModuleOptions? options}) : super(options: options);

  @override

  /// Register the [ConfigService] provider.
  ///
  /// This method will load the environment variables from the `.env` file and register the [ConfigService] provider.
  ///
  /// Optionally, you can pass a [ConfigModuleOptions] object to configure the module.
  Future<Module> registerAsync(ApplicationConfig config) async {
    final moduleOptions =
        options as ConfigModuleOptions? ?? ConfigModuleOptions();
    final dotEnv = DotEnv(includePlatformEnvironment: true)
      ..load([moduleOptions.dotEnvPath]);
    providers = [ConfigService(dotEnv)];
    exports = [ConfigService];
    return this;
  }
}

/// Options for the [ConfigModule].
///
/// You can pass a [dotEnvPath] to specify the path to the `.env` file.
class ConfigModuleOptions extends ModuleOptions {
  final String dotEnvPath;

  ConfigModuleOptions({this.dotEnvPath = '.env'});
}
