import 'package:serinus/serinus.dart';

typedef FrontierDeserializer<T> = T Function(Object? value);

/// Holds the configuration for the Frontier module
class FrontierConfig {

  final String? defaultStrategy;

  final FrontierDeserializer? deserializer;
  
  // You can add other global settings here later, like:
  // final bool session;
  // final String property; // e.g., 'user' vs 'account'

  const FrontierConfig({this.defaultStrategy, this.deserializer});
}

// packages/serinus_frontier/lib/src/frontier_module.dart
/// The FrontierModule configures defaults for authentication within Serinus.
class FrontierModule extends Module {
  
  final String? defaultStrategy;

  final FrontierDeserializer? deserializer;

  /// Configures the FrontierModule with global defaults.
  /// 
  /// Example: `FrontierModule.register(defaultStrategy: 'jwt')`
  FrontierModule({this.defaultStrategy, this.deserializer});

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    // You can perform any async initialization here if needed
    return DynamicModule(
      providers: [
        Provider.forValue<FrontierConfig>(
          FrontierConfig(defaultStrategy: defaultStrategy, deserializer: deserializer),
        ),
      ],
      exports: [
        Export.value<FrontierConfig>()
      ],
    );
  }
  
}
