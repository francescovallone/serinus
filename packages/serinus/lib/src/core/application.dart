import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';

import '../adapters/adapters.dart';
import '../containers/serinus_container.dart';
import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../extensions/string_extensions.dart';
import '../global_prefix.dart';
import '../microservices/microservices.dart';
import '../mixins/mixins.dart';
import '../routes/routes_resolver.dart';
import '../services/cluster_service.dart';
import '../services/logger_service.dart';
import '../versioning.dart';
import 'core.dart';

/// The [Application] class is used to create an application.
abstract class Application {
  /// The [level] property contains the log level of the application.
  Set<LogLevel> get levels => Logger.logLevels;

  /// The [logger] property contains the logger of the application.
  final logger = Logger('Application');

  /// The [entrypoint] property contains the entry point of the application.
  final Module entrypoint;
  bool _enableShutdownHooks = false;
  bool _shuttingDown = false;

  /// The [container] property contains the Serinus container of the application.
  /// It is used to access the modules and their dependencies and also the adapters.
  SerinusContainer _container;

  /// The [RoutesResolver] property contains the resolver of the application.
  RoutesResolver? _routesResolver;

  /// The [config] property contains the application configuration.
  final ApplicationConfig config;

  /// Whether to abort the application on error.
  final bool abortOnError;

  @visibleForTesting
  /// The [container] getter is used to get the Serinus container of the application.
  SerinusContainer get container => _container;

  @visibleForTesting
  set container(SerinusContainer container) {
    _container = container;
    _routesResolver = RoutesResolver(_container);
  }

  /// The [Application] constructor is used to create a new instance of the [Application] class.
  Application({
    required this.entrypoint,
    required this.config,
    this.abortOnError = true,
    Set<LogLevel>? levels,
    LoggerService? logger,
  }) : _container = SerinusContainer(config, config.serverAdapter) {
    _routesResolver = RoutesResolver(_container);
    if (levels != null) {
      Logger.setLogLevels(levels);
    }
    if (logger != null) {
      Logger.overrideLogger(logger);
    }
  }

  bool _isInitialized = false;

  /// The [initialize] method initializes the application and instructs the container to initialize the modules and their dependencies.
  Future<void> initialize() async {
    try {
      if (_isInitialized) {
        return;
      }
      _isInitialized = true;
      await _container.init(entrypoint, _routesResolver);
    } catch (e) {
      if (abortOnError) {
        rethrow;
      }
      logger.severe(
        'Error occurred while initializing application',
        OptionalParameters(error: e, stackTrace: StackTrace.current),
      );
    }
  }

  /// The [url] property contains the URL of the application.
  String get url;

  /// The [server] property contains the server of the application.
  HttpAdapter get server => config.serverAdapter;

  /// The [enableShutdownHooks] method is used to enable the shutdown hooks.
  void enableShutdownHooks() {
    if (!_enableShutdownHooks) {
      _enableShutdownHooks = true;
      // Listen for common termination signals and perform graceful shutdown.
      void handleSignal(ProcessSignal _) async {
        if (_shuttingDown) {
          return;
        }
        _shuttingDown = true;
        try {
          await close();
        } catch (e) {
          // Log the error but continue with exit to ensure process terminates
          try {
            logger.severe(
              'Error during shutdown',
              OptionalParameters(error: e),
            );
          } catch (_) {
            // If logging fails, silently continue
          }
        }
        // Ensure process exits after shutdown
        exit(0);
      }

      // SIGINT (Ctrl+C)
      try {
        ProcessSignal.sigint.watch().listen(handleSignal);
      } catch (_) {
        // Signal not supported on this platform, continue without it
      }

      // On Windows SIGTERM and SIGHUP are not supported; only register them
      // on non-Windows platforms.
      if (!Platform.isWindows) {
        // SIGTERM (graceful termination)
        try {
          ProcessSignal.sigterm.watch().listen(handleSignal);
        } catch (_) {
          // Signal not supported on this platform, continue without it
        }

        // SIGHUP / others may be supported on some platforms
        try {
          ProcessSignal.sighup.watch().listen(handleSignal);
        } catch (_) {
          // Signal not supported on this platform, continue without it
        }
      }
    }
  }

  /// The [shutdown] method is used to shutdown the application.
  @internal
  Future<void> shutdown();

  /// The [register] method is used to register the application.
  Future<void> register();

  /// The [serve] method is used to serve the application.
  Future<void> serve();

  /// The [close] method is used to close the application.
  Future<void> close();
}

/// The [MicroserviceApplication] class is used to create a new instance of the [Application] class.
class MicroserviceApplication extends Application {
  @override
  final logger = Logger('MicroserviceApplication');

  /// The [MicroserviceApplication] constructor is used to create a new instance of the [MicroserviceApplication] class.
  MicroserviceApplication({
    required super.entrypoint,
    required super.config,
    super.levels,
    super.logger,
  });

  @override
  String get url => 'microservice';

  bool _isInizialized = false;

  @override
  Future<void> serve() async {
    try {
      logger.info(
        'Starting microservice on ${config.microservices.first.runtimeType} adapter',
      );
      for (final microservice in config.microservices) {
        await microservice.init(config);
      }
      await initialize();
      await _container.emitHook<OnApplicationReady>();
    } catch (e) {
      if (abortOnError) {
        rethrow;
      }
      logger.severe(
        'Error occurred while starting microservices',
        OptionalParameters(error: e, stackTrace: StackTrace.current),
      );
    }
  }

  @override
  Future<void> close() async {
    for (final adapter in config.adapters.values) {
      await adapter.close();
    }
    for (final microservice in config.microservices) {
      await microservice.close();
    }
    await config.serverAdapter.close();
    await shutdown();
  }

  @override
  Future<void> initialize() async {
    try {
      if (_isInizialized) {
        return;
      }
      _isInizialized = true;
      await _container.init(entrypoint, _routesResolver);
    } catch (e) {
      if (abortOnError) {
        rethrow;
      }
      logger.severe(
        'Error occurred while initializing application',
        OptionalParameters(error: e, stackTrace: StackTrace.current),
      );
    }
  }

  @override
  Future<void> shutdown() async {
    logger.info('Shutting down microservices');
    await _container.emitHook<OnApplicationShutdown>();
  }

  @override
  Future<void> register() {
    return _container.modulesContainer.registerModules(entrypoint);
  }
}

/// The [SerinusApplication] class is used to create a new instance of the [Application] class.
class SerinusApplication extends Application {
  @override
  final logger = Logger('SerinusApplication');

  final List<TransportAdapter> _microservices = [];

  /// The [SerinusApplication] constructor is used to create a new instance of the [SerinusApplication] class.
  SerinusApplication({
    required super.entrypoint,
    required super.config,
    super.levels,
    super.logger,
  });

  @override
  String get url => config.baseUrl;

  /// The [viewEngine] method is used to set the view engine of the application.
  set viewEngine(ViewEngine viewEngine) {
    _container.applicationRef.viewEngine = viewEngine;
  }

  /// The [versioning] setter is used to enable versioning.
  set versioning(VersioningOptions options) {
    _container.config.versioningOptions = options;
  }

  /// The [globalPrefix] setter is used to set the global prefix of the application.
  set globalPrefix(String prefix) {
    if (prefix == '/') {
      return;
    }
    _container.config.globalPrefix = GlobalPrefix(
      prefix: prefix.addLeadingSlash().stripEndSlash(),
    );
  }

  @override
  Future<void> serve() async {
    try {
      if (config.microservices.isNotEmpty) {
        logger.info('Starting microservices');
        for (final microservice in config.microservices) {
          await microservice.init(config);
        }
      }
      await initialize();
      logger.info('Starting server on $url');
      server.listen(
        onRequest: (request, response) =>
            _routesResolver!.handle(request, response),
      );
      await _container.emitHook<OnApplicationReady>();
    } on SocketException catch (e) {
      logger.severe('Failed to start server on ${e.address}:${e.port}');
      await close();
    } catch (e) {
      if (abortOnError) {
        rethrow;
      }
      logger.severe(
        'Error occurred while starting server',
        OptionalParameters(error: e, stackTrace: StackTrace.current),
      );
    }
  }

  @override
  Future<void> close() async {
    for (final adapter in config.adapters.values) {
      await adapter.close();
    }
    for (final microservice in config.microservices) {
      await microservice.close();
    }
    await config.serverAdapter.close();
    await shutdown();
  }

  /// The [connectMicroservice] method is used to connect a microservice to the application.
  /// It takes a [TransportAdapter] as a parameter and adds it to the list of microservices.
  /// It also checks if the port of the microservice is already in use by another microservice or the main application.
  TransportInstance connectMicroservice(TransportAdapter adapter) {
    final allPorts = [
      config.port,
      ..._microservices.map((e) => e.options.port),
    ];
    if (allPorts.contains(adapter.options.port)) {
      throw ArgumentError(
        'Microservice port (${adapter.options.port}) is already in use by another microservice or the main application',
      );
    }
    config.microservices.add(adapter);
    return TransportInstance(adapter);
  }

  /// The [startAllMicroservices] method is used to start all microservices.
  Future<void> startAllMicroservices() async {
    for (final microservice in config.microservices) {
      await microservice.init(config);
    }
    if (!_isInitialized) {
      await initialize();
    }
    _isInitialized = true;
  }

  @override
  Future<void> shutdown() async {
    logger.info('Shutting down server');
    await _container.emitHook<OnApplicationShutdown>();
  }

  @override
  Future<void> register() async {
    _container.modulesContainer.registerModules(entrypoint);
  }

  /// The [use] method is used to add a hook to the application.
  void use(Processable processable) {
    switch (processable) {
      case Hook():
        _container.config.globalHooks.addHook(processable);
        logger.verbose(
          'Global Hook ${processable.runtimeType} added to application',
        );
        break;
      case Pipe():
        _container.config.globalPipes.add(processable);
        logger.verbose(
          'Global Pipe ${processable.runtimeType} added to application',
        );
        break;
      case ExceptionFilter():
        _container.config.globalExceptionFilters.add(processable);
        logger.verbose(
          'Global ExceptionFilter ${processable.runtimeType} added to application',
        );
        break;
      case Middleware():
      default:
        throw ArgumentError(
          'Unknown processable type: ${processable.runtimeType}',
        );
    }
  }

  // /// The [trace] method is used to add a tracer to the application.
  // void trace(Tracer tracer) {
  //   config.registerTracer(tracer);
  //   _logger.info(
  //     'Tracer ${tracer.name}(${tracer.runtimeType}) added to application',
  //   );
  // }
}

/// Manages the lifecycle of a Serinus Cluster.
class ClusterApplication extends Application {
  Map<String, Isolate> _workers = {};
  Map<String, SendPort> _workerPorts = {};
  ReceivePort? _orchestratorPort;
  final Map<String, ReceivePort> _workerErrorsPort = {};
  final Map<String, ReceivePort> _workerExitPort = {};
  /// Configuration for worker isolates, passed during their initialization to ensure consistent setup across the cluster.
  final WorkerConfig workerConfig;
  /// The number of worker isolates to spawn in the cluster, typically set to the number of CPU cores for optimal performance.
  final int workersCount;
  final Completer<void> _shuttedDown = Completer();
  final Map<String, Completer<void>> _workerRegistrations = {};
  final Map<String, int> _workerRestartAttempts = {};
  final Set<String> _restartingWorkers = {};
  bool _serveIssued = false;
  bool _registered = false;
  bool _isClosing = false;
  static const int _maxRestartAttempts = 5;
  static const Duration _baseRestartDelay = Duration(milliseconds: 250);
  /// Logger for the ClusterApplication, used to log cluster lifecycle events and errors.
  final orchestratorLogger = Logger('Orchestrator');

  /// The [ClusterApplication] constructor is used to create a new instance of the [ClusterApplication] class.
  ClusterApplication({
    required super.entrypoint, 
    required super.config, 
    required this.workersCount,
    required this.workerConfig,
    super.levels,
    super.logger,
  });

  /// Gracefully shuts down all workers and closes the cluster.
  @override
  Future<void> close() async {
    _isClosing = true;
    logger.info('Initiating graceful shutdown of cluster...');

    // 1. Send shutdown signal to all workers so they can close resources
    for (final port in _workerPorts.values) {
      port.send('SHUTDOWN');
    }

    // 2. Wait a brief moment for the HTTP adapters to finish closing
    await Future.delayed(const Duration(seconds: 2));

    // 3. Force kill isolates to clean up memory
    for (final isolate in _workers.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    for (final errorPort in _workerErrorsPort.values) {
      errorPort.close();
    }
    for (final exitPort in _workerExitPort.values) {
      exitPort.close();
    }
    _workerErrorsPort.clear();
    _workerExitPort.clear();
    _orchestratorPort?.close();
    if (!_shuttedDown.isCompleted) {
      _shuttedDown.complete();
    }
    logger.info('Cluster shutdown complete.');
  }

  Duration _restartDelay(int attempt) {
    // Exponential backoff capped to avoid very long pauses.
    final multiplier = 1 << (attempt - 1).clamp(0, 5);
    final delay = _baseRestartDelay * multiplier;
    return delay > const Duration(seconds: 8)
        ? const Duration(seconds: 8)
        : delay;
  }

  Future<void> _spawnWorker(String workerId) async {
    _workerErrorsPort[workerId]?.close();
    _workerExitPort[workerId]?.close();

    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    _workerErrorsPort[workerId] = errorPort;
    _workerExitPort[workerId] = exitPort;

    errorPort.listen((dynamic error) {
      orchestratorLogger.severe(
        'Worker isolate error ($workerId)',
        OptionalParameters(error: error),
      );
      unawaited(_handleWorkerFailure(workerId));
    });

    exitPort.listen((_) {
      orchestratorLogger.warning('Worker isolate exited ($workerId).');
      unawaited(_handleWorkerFailure(workerId));
    });

    final isolate = await Isolate.spawn(
      _workerEntry,
      _ClusterConfig(
        _bootstrapClusterApp(
          entrypoint: entrypoint,
          workerConfig: workerConfig,
        ),
        _orchestratorPort!.sendPort,
        workerId,
      ),
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );
    _workers[workerId] = isolate;
  }

  Future<void> _handleWorkerFailure(String workerId) async {
    if (_isClosing || !_registered || _shuttedDown.isCompleted) {
      return;
    }
    if (_restartingWorkers.contains(workerId)) {
      return;
    }

    _restartingWorkers.add(workerId);
    try {
      _workerPorts.remove(workerId);
      _workers.remove(workerId);

      final nextAttempt = (_workerRestartAttempts[workerId] ?? 0) + 1;
      _workerRestartAttempts[workerId] = nextAttempt;

      if (nextAttempt > _maxRestartAttempts) {
        orchestratorLogger.severe(
          'Worker $workerId exceeded restart attempts ($_maxRestartAttempts). Shutting down cluster.',
        );
        await close();
        return;
      }

      final delay = _restartDelay(nextAttempt);
      orchestratorLogger.warning(
        'Restarting worker $workerId in ${delay.inMilliseconds}ms (attempt $nextAttempt/$_maxRestartAttempts).',
      );
      await Future.delayed(delay);

      if (_isClosing || _shuttedDown.isCompleted) {
        return;
      }

      _workerRegistrations[workerId] = Completer<void>();
      await _spawnWorker(workerId);
    } finally {
      _restartingWorkers.remove(workerId);
    }
  }

  Future<void> _waitForWorkerRegistrations({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final pending = _workerRegistrations.values
        .where((completer) => !completer.isCompleted)
        .map((completer) => completer.future)
        .toList();

    if (pending.isEmpty) {
      return;
    }

    await Future.wait(pending).timeout(timeout, onTimeout: () {
      final missing = _workerRegistrations.entries
          .where((entry) => !entry.value.isCompleted)
          .map((entry) => entry.key)
          .toList();
      orchestratorLogger.warning(
        'Timeout waiting for worker registration. Missing: ${missing.join(', ')}',
      );
      return [];
    });
  }
  
  static Future<SerinusApplication> Function() _bootstrapClusterApp({
    required Module entrypoint,
    required WorkerConfig workerConfig,
  }) {
    return () => serinus.createApplication(
      entrypoint: entrypoint,
      host: workerConfig.host,
      port: workerConfig.port,
      logLevels: workerConfig.logLevels,
      logger: workerConfig.logger,
      poweredByHeader: workerConfig.poweredByHeader,
      securityContext: workerConfig.securityContext,
      modelProvider: workerConfig.modelProvider,
      enableCompression: workerConfig.enableCompression,
      rawBody: workerConfig.rawBody,
      notFoundHandler: workerConfig.notFoundHandler,
      bodySizeLimit: workerConfig.bodySizeLimit,
    );
  }

  static Future<void> _workerEntry(_ClusterConfig config) async {
    // 1. Override the default ConsoleLogger before anything else!
    Logger.overrideLogger(WorkerLogger(config.orchestratorPort, config.workerId));

    // 2. Bootstrap application
    final app = await config.bootstrap();
    
    // 3. Setup Cluster Service with the assigned Worker ID
    final clusterService = ClusterService(config.orchestratorPort, config.workerId);
    
    // 4. Handle control signals from orchestrator.
    clusterService.onControlMessage.listen((msg) async {
      try {
        if (msg == 'SHUTDOWN') {
          await app.close();
        }
        if (msg == 'SERVE') {
          await app.serve();
        }
      } catch (e, stackTrace) {
        Logger('Worker').severe(
          'Error handling control message "$msg"',
          OptionalParameters(error: e, stackTrace: stackTrace),
        );
      }
    });

    // 5. Wire up Syncable providers
    // ignore: invalid_use_of_visible_for_testing_member
    final container = app.container.modulesContainer;
    for (final scope in container.scopes) {
      for (final provider in scope.providers) {
        if (provider is Syncable) {
          provider.initSync(clusterService);
        }
      }
    }
  }

  @override
  Future<void> register() async {
    if (_registered) {
      return;
    }
    _registered = true;

    _orchestratorPort = ReceivePort();

    for (var i = 1; i <= workersCount; i++) {
      final workerId = 'Worker-$i';
      _workerRegistrations[workerId] = Completer<void>();
      _workerRestartAttempts[workerId] = 0;
      await _spawnWorker(workerId);
    }

    // Process Orchestrator Messages in the background
    _orchestratorPort?.listen((message) {
      if (message is List) {
        if (message[0] == 'REGISTER') {
          final id = message[1] as String;
          final port = message[2] as SendPort;
          _workerPorts[id] = port;
          _workerRestartAttempts[id] = 0;
          _workerRegistrations[id]?.complete();
          orchestratorLogger.info('Registered $id');

          // If orchestrator already issued serve, start late-registered workers too.
          if (_serveIssued) {
            port.send('SERVE');
          }
        } else if (message[0] == 'LOG') {
          // Reconstruct and pipe the worker's log through the Orchestrator's ConsoleLogger
          final workerId = message[1] as String;
          final levelName = message[2] as String;
          final msg = message[3] as String?;
          final ctx = message[4] as String?;
          final err = message[5] as String?;
          final st = message[6] as String?;

          final level = LogLevel.values.firstWhere((e) => e.name == levelName, orElse: () => LogLevel.info);
          
          final params = OptionalParameters(
            error: err,
            stackTrace: st == null ? null : StackTrace.fromString(st),
          );
          params.context = '${ctx ?? 'App'} [$workerId]'; // e.g. [Application] [Worker-1]

          final logger = Logger(ctx ?? 'Cluster');
          switch (level) {
            case LogLevel.info: logger.info(msg, params); break;
            case LogLevel.severe: logger.severe(msg, params); break;
            case LogLevel.warning: logger.warning(msg, params); break;
            case LogLevel.debug: logger.debug(msg, params); break;
            case LogLevel.verbose: logger.verbose(msg, params); break;
            case LogLevel.shout: logger.shout(msg, params); break;
            case LogLevel.none:
              // No logging
              break;
          }
        } else if (message[0] == 'SHUTDOWN') {
          orchestratorLogger.info('Received shutdown signal. Terminating workers...');
          for (final isolate in _workers.values) {
            isolate.kill(priority: Isolate.immediate);
          }
          _orchestratorPort?.close();
          if (!_shuttedDown.isCompleted) {
            _shuttedDown.complete();
          }
        }
      } else if (message is ClusterMessage) {
        // Broadcast sync messages
        for (final entry in _workerPorts.entries) {
          if (entry.key != message.senderId) {
            entry.value.send(message);
          }
        }
      }
    });
  }
  
  @override
  Future<void> serve() async {
    await register();
    await _waitForWorkerRegistrations();

    // In a cluster setup, the workers will handle serving. The Orchestrator just manages them.
    _serveIssued = true;
    for (final port in _workerPorts.values) {
      port.send('SERVE');
    }
    logger.info('Cluster is up with $workersCount workers. Orchestrator is now managing worker lifecycle.');
    logger.info('Workers are listening on $url');
    return _shuttedDown.future; // Keep the Orchestrator alive until shutdown
  }
  
  @override
  Future<void> shutdown() async {
     logger.info('Shutting down cluster application');
     await close();
  }
  
  @override
  String get url => '${workerConfig.host}:${workerConfig.port}';
}

/// A Logger implementation that serializes logs and sends them to the Orchestrator.
class WorkerLogger implements LoggerService {
  /// The [WorkerLogger] constructor is used to create a new instance of the [WorkerLogger] class.
  final SendPort orchestratorPort;
  /// Unique identifier for the worker isolate, used to tag log messages.
  final String workerId;

  /// Creates a WorkerLogger that sends log messages to the Orchestrator via the provided SendPort.
  WorkerLogger(this.orchestratorPort, this.workerId);

  void _log(LogLevel level, Object? message, OptionalParameters? params) {
    orchestratorPort.send([
      'LOG',
      workerId,
      level.name,
      message?.toString(),
      params?.context,
      params?.error?.toString(),
      params?.stackTrace?.toString(),
    ]);
  }

  @override void info(Object? message, [OptionalParameters? p]) => _log(LogLevel.info, message, p);
  @override void verbose(Object? message, [OptionalParameters? p]) => _log(LogLevel.verbose, message, p);
  @override void shout(Object? message, [OptionalParameters? p]) => _log(LogLevel.shout, message, p);
  @override void warning(Object? message, [OptionalParameters? p]) => _log(LogLevel.warning, message, p);
  @override void debug(Object? message, [OptionalParameters? p]) => _log(LogLevel.debug, message, p);
  @override void severe(Object? message, [OptionalParameters? p]) => _log(LogLevel.severe, message, p);
}

class _ClusterConfig {
  final Future<SerinusApplication> Function() bootstrap;
  final SendPort orchestratorPort;
  final String workerId;
  const _ClusterConfig(this.bootstrap, this.orchestratorPort, this.workerId);
}