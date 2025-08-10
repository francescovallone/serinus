import 'dart:io';

import '../adapters/adapters.dart';
import '../constants.dart';
import '../containers/model_provider.dart';
import '../enums/log_level.dart';
import '../services/logger_service.dart';
import 'core.dart';

/// The [SerinusFactory] class is used to create a new instance of the [SerinusApplication] class.
final class SerinusFactory {
  /// The [SerinusFactory] constructor is used to create a new instance of the [SerinusFactory] class.
  const SerinusFactory();

  /// The [createApplication] method is used to create a new instance of the [SerinusApplication] class.
  ///
  /// It takes an [entrypoint] module, a [host] string, a [port] integer, a [loggingLevel] LogLevel, a [loggerService] LoggerService, a [poweredByHeader] string, a [securityContext] SecurityContext, and an [enableCompression] boolean.
  ///
  /// It returns a [Future] of [SerinusApplication].
  Future<SerinusApplication> createApplication(
      {required Module entrypoint,
      String host = 'localhost',
      int port = 3000,
      Set<LogLevel>? logLevels,
      LoggerService? logger,
      String poweredByHeader = 'Powered by Serinus',
      SecurityContext? securityContext,
      ModelProvider? modelProvider,
      bool enableCompression = true,
      bool rawBody = false,
      NotFoundHandler? notFoundHandler}) async {
    final serverPort = int.tryParse(Platform.environment['PORT'] ?? '') ?? port;
    final serverHost = Platform.environment['HOST'] ?? host;
    final server = SerinusHttpAdapter(
        host: serverHost,
        port: serverPort,
        poweredByHeader: poweredByHeader,
        securityContext: securityContext,
        enableCompression: enableCompression,
        rawBody: rawBody,
        notFoundHandler: notFoundHandler);
    await server.init();
    final app = SerinusApplication(
        entrypoint: entrypoint,
        config: ApplicationConfig(
          serverAdapter: server,
          modelProvider: modelProvider,

        ),
        levels: logLevels ?? (kDebugMode ? {LogLevel.verbose} : {LogLevel.info}),
        logger: logger);
    return app;
  }
}

/// The [serinus] instance is used to create a new instance of the [SerinusFactory] class.
const serinus = SerinusFactory();
