import 'dart:io';
import 'dart:isolate';

import '../adapters/adapters.dart';
import '../constants.dart';
import '../containers/models_provider.dart';
import '../enums/log_level.dart';
import '../http/http.dart';
import '../microservices/microservices.dart';
import '../services/cluster_service.dart';
import '../services/logger_service.dart';
import 'core.dart';
import 'minimal/minimal_application.dart';

/// The [SerinusFactory] class is used to create a new instance of the [SerinusApplication] class.
final class SerinusFactory {
  /// The [SerinusFactory] constructor is used to create a new instance of the [SerinusFactory] class.
  const SerinusFactory();

  /// The [createApplication] method is used to create a new instance of the [SerinusApplication] class.
  ///
  /// It takes an [entrypoint] module, a [host] string, a [port] integer, a [loggingLevel] LogLevel, a [loggerService] LoggerService, a [poweredByHeader] string, a [securityContext] SecurityContext, and an [enableCompression] boolean.
  ///
  /// It returns a [Future] of [SerinusApplication].
  Future<SerinusApplication> createApplication({
    required Module entrypoint,
    String host = 'localhost',
    int port = 3000,
    Set<LogLevel>? logLevels,
    LoggerService? logger,
    String poweredByHeader = 'Powered by Serinus',
    SecurityContext? securityContext,
    ModelProvider? modelProvider,
    bool enableCompression = true,
    bool rawBody = false,
    NotFoundHandler? notFoundHandler,
    int bodySizeLimit = kDefaultMaxBodySize,
  }) async {
    final serverPort = int.tryParse(Platform.environment['PORT'] ?? '') ?? port;
    final serverHost = Platform.environment['HOST'] ?? host;
    final server = SerinusHttpAdapter(
      host: serverHost,
      port: serverPort,
      poweredByHeader: poweredByHeader,
      securityContext: securityContext,
      enableCompression: enableCompression,
      rawBody: rawBody,
      notFoundHandler: notFoundHandler,
    );
    IncomingMessage.maxBodySize = bodySizeLimit;
    await server.init();
    final app = SerinusApplication(
      entrypoint: entrypoint,
      config: ApplicationConfig(
        serverAdapter: server,
        modelProvider: modelProvider,
      ),
      levels: logLevels ?? (kDebugMode ? {LogLevel.verbose} : {LogLevel.info}),
      logger: logger,
    );
    return app;
  }

  Future<void> cluster(
    Future<SerinusApplication> Function() bootstrap, {
    int? workers,
  }) async {
    final int workerCount = workers ?? Platform.numberOfProcessors;
    final orchestratorPort = ReceivePort();
    
    // Track workers by their ID to prevent echoes
    final workerPorts = <String, SendPort>{};
    
    // 1. Spawn Workers
    for (var i = 0; i < workerCount; i++) {
      await Isolate.spawn(
        _workerEntry,
        _ClusterConfig(bootstrap, orchestratorPort.sendPort),
      );
    }

    // 2. Orchestrator Loop (Main Isolate)
    await for (final message in orchestratorPort) {
      
      if (message is List && message.length == 3 && message[0] == 'REGISTER') {
        // Handle worker registration
        final id = message[1] as String;
        final port = message[2] as SendPort;
        workerPorts[id] = port;
        print('Orchestrator: Worker $id registered.');
        
      } else if (message is ClusterMessage) {
        // Broadcast to all workers EXCEPT the one who sent it
        for (final entry in workerPorts.entries) {
          if (entry.key != message.senderId) {
            entry.value.send(message);
          }
        }
      }
      
    }
  }

  static void _workerEntry(_ClusterConfig config) async {
    final app = await config.bootstrap();
    
    // A. Create ClusterService
    final clusterService = ClusterService(config.orchestratorPort);
    
    // B. Auto-Wire Syncable Providers
    // ignore: invalid_use_of_visible_for_testing_member
    final container = app.container.modulesContainer;
    
    for (final scope in container.scopes) {
      for (final provider in scope.providers) {
        if (provider is Syncable) {
          provider.initSync(clusterService);
        }
      }
    }

    await app.serve();
  }

  /// The [createMicroservice] method is used to create a new instance of the [MicroserviceApplication] class.
  Future<MicroserviceApplication> createMicroservice({
    required Module entrypoint,
    required TransportAdapter transport,
    Set<LogLevel>? logLevels,
    LoggerService? logger,
    ModelProvider? modelProvider,
  }) async {
    final app = MicroserviceApplication(
      entrypoint: entrypoint,
      config: ApplicationConfig(
        modelProvider: modelProvider,
        serverAdapter: NoopAdapter(),
      )..microservices.add(transport),
      levels: logLevels ?? (kDebugMode ? {LogLevel.verbose} : {LogLevel.info}),
      logger: logger,
    );
    return app;
  }

  /// The [createMinimalApplication] method is used to create a new instance of the [SerinusMinimalApplication] class.
  Future<SerinusMinimalApplication> createMinimalApplication({
    String host = 'localhost',
    int port = 3000,
    Set<LogLevel>? logLevels,
    LoggerService? logger,
    String poweredByHeader = 'Powered by Serinus',
    SecurityContext? securityContext,
    ModelProvider? modelProvider,
    bool enableCompression = true,
    bool rawBody = false,
    NotFoundHandler? notFoundHandler,
    int bodySizeLimit = kDefaultMaxBodySize,
  }) async {
    final serverPort = int.tryParse(Platform.environment['PORT'] ?? '') ?? port;
    final serverHost = Platform.environment['HOST'] ?? host;
    final server = SerinusHttpAdapter(
      host: serverHost,
      port: serverPort,
      poweredByHeader: poweredByHeader,
      securityContext: securityContext,
      enableCompression: enableCompression,
      rawBody: rawBody,
      notFoundHandler: notFoundHandler,
    );
    IncomingMessage.maxBodySize = bodySizeLimit;
    await server.init();
    final app = SerinusMinimalApplication(
      config: ApplicationConfig(
        serverAdapter: server,
        modelProvider: modelProvider,
      ),
      levels: logLevels ?? (kDebugMode ? {LogLevel.verbose} : {LogLevel.info}),
      logger: logger,
    );
    return app;
  }
}

/// The [serinus] instance is used to create a new instance of the [SerinusFactory] class.
const serinus = SerinusFactory();

class _ClusterConfig {
  final Future<SerinusApplication> Function() bootstrap;
  final SendPort orchestratorPort;
  const _ClusterConfig(this.bootstrap, this.orchestratorPort);
}