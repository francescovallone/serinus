import 'dart:io';

import 'package:serinus/serinus.dart';

class SerinusFactory {
  const SerinusFactory();

  Future<SerinusApplication> createApplication(
      {required Module entrypoint,
      String host = 'localhost',
      int port = 3000,
      LogLevel loggingLevel = LogLevel.debug,
      LoggerService? loggerService,
      String poweredByHeader = 'Powered by Serinus',
      SecurityContext? securityContext}) async {
    final server = SerinusHttpServer();
    final serverPort = int.tryParse(Platform.environment['PORT'] ?? '') ?? port;
    final serverHost = Platform.environment['HOST'] ?? host;
    await server.init(
        securityContext: securityContext,
        poweredByHeader: poweredByHeader,
        port: serverPort,
        host: serverHost);
    final app = SerinusApplication(
        entrypoint: entrypoint,
        config: ApplicationConfig(
            host: serverHost,
            port: serverPort,
            poweredByHeader: poweredByHeader,
            securityContext: securityContext,
            serverAdapter: server),
        level: loggingLevel,
        loggerService: loggerService);
    return app;
  }
}

const serinus = SerinusFactory();
