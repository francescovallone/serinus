import '../core/core.dart';
import 'body_parser_registry.dart';

/// A module for processing request bodies.
class BodyProcessingModule extends Module {

  /// Creates a new instance of [BodyProcessingModule].
  BodyProcessingModule(): super(isGlobal: true);

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    return DynamicModule(
      providers: [
        BodyProcessingService(
          config.bodyParsers
        )
      ]
    );
  }
}

/// A service for processing request bodies.
class BodyProcessingService extends Provider{

  final BodyParserRegistry _bodyParserRegistry;

  /// Creates a new instance of [BodyProcessingService].
  BodyProcessingService(this._bodyParserRegistry);

}