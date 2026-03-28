import 'package:serinus/serinus.dart';

typedef FrontierDeserializer<T> = T Function(Object? value);

/// Holds the configuration for the Frontier module
class FrontierConfig {
  final FrontierDeserializer? deserializer;

  // You can add other global settings here later, like:
  // final bool session;
  // final String property; // e.g., 'user' vs 'account'

  const FrontierConfig({this.deserializer});
}

/// The FrontierModule configures defaults for authentication within Serinus.
class FrontierModule extends Module {

  final FrontierDeserializer? deserializer;

  /// Configures the FrontierModule with global defaults.
  ///
  /// Example: `FrontierModule(deserializer: (value) => MyUser.fromJson(value))`
  FrontierModule({this.deserializer});

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    return DynamicModule(
      providers: [
        Provider.forValue<FrontierConfig>(
          FrontierConfig(
            deserializer: deserializer,
          ),
        ),
      ],
      exports: [Export.value<FrontierConfig>()],
    );
  }
}
