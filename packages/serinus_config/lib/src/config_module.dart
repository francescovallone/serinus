import 'package:dotenv/dotenv.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_config/src/config_service.dart';

abstract class ParsedConfig extends Provider {}

typedef ConfigFactory = ParsedConfig Function(DotEnv env);

/// A module that provides a [ConfigService] that can be used to access environment variables.
class ConfigModule extends Module {

  final bool includePlatformEnvironment;

  final List<String> paths;

  final List<ConfigFactory> factories;

  /// Create a new instance of [ConfigModule].
  ///
  /// Optionally, you can pass a [ConfigModuleOptions] object to configure the module.
  ConfigModule({
    @Deprecated('Use `paths` instead')
    String? dotEnvPath,
    this.includePlatformEnvironment = true,
    this.paths = const ['.env'],
    this.factories = const [],
    super.isGlobal = true,
  }) : assert(paths.isNotEmpty, 'At least one path must be provided') {
    if (dotEnvPath != null && !paths.contains(dotEnvPath)) {
      paths.add(dotEnvPath);
    }
  }


  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final dotEnv = DotEnv(includePlatformEnvironment: includePlatformEnvironment)..load(paths);
    providers = [
      ConfigService(dotEnv),
      ...factories.map((factory) => factory(dotEnv)),
    ];
    return DynamicModule(
      providers: providers,
      exports: [
        if (!isGlobal) ...(providers.map((e) => e.runtimeType))
      ],
    );
  }
}
