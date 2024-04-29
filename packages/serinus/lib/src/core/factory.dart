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
    await server.init(
        securityContext: securityContext,
        poweredByHeader: poweredByHeader,
        port: int.tryParse(Platform.environment['PORT'] ?? '') ?? port,
        host: Platform.environment['HOST'] ?? host);
    final app = SerinusApplication(
        entrypoint: entrypoint,
        serverAdapter: server,
        level: loggingLevel,
        loggerService: loggerService);
    await app.initialize();
    return app;
  }
}

const serinus = SerinusFactory();
