import 'dart:io';

import 'package:uuid/v4.dart';

import '../adapters/adapters.dart';
import '../containers/adapters_container.dart';
import '../containers/hooks_container.dart';
import '../containers/models_provider.dart';
import '../containers/modules_container.dart';
import '../engines/view_engine.dart';
import '../enums/enums.dart';
import '../global_prefix.dart';
import '../http/internal_request.dart';
import '../microservices/transports/transports.dart';
import '../services/logger_service.dart';
import '../services/tracers_service.dart';
import '../versioning.dart';
import 'exception_filter.dart';
import 'pipe.dart' as s;
import 'tracer.dart';

/// The configuration for the application
/// This is used to configure the application
final class ApplicationConfig {
  /// The host to be used by the application
  /// Default is 'localhost'
  ///
  /// This can be changed to any value
  String get host => serverAdapter.host;

  /// The port to be used by the application
  /// Default is 3000
  ///
  /// This can be changed to any value
  int get port => serverAdapter.port;

  /// The header to be sent with the response
  /// Default is 'Powered by Serinus'
  /// This can be changed to any value
  String? get poweredByHeader => serverAdapter.poweredByHeader;

  /// The security context for the application if any
  /// If not provided, the application will be created as a normal http server
  /// If provided, the application will be created as a secure https server
  SecurityContext? get securityContext => serverAdapter.securityContext;

  /// The applicationId, every application has a unique id
  final String applicationId = UuidV4().generate();

  /// The list of microservices in the application.
  final List<TransportAdapter> microservices = [];

  /// The versioning options for the application
  /// This can be set using the [versioning] method
  /// The versioning options can be set only once
  /// If the versioning options are already set, a [StateError] will be thrown
  VersioningOptions? _versioningOptions;

  /// The view engine for the application
  /// This can be set using the [useViewEngine] method
  /// The view engine can be set only once
  /// If the view engine is already set, a [StateError] will be thrown
  ViewEngine? _viewEngine;

  /// The global prefix for the application
  /// This can be set using the [setGlobalPrefix] method
  /// The global prefix can be set only once
  /// If the global prefix is already set, a [StateError] will be thrown
  /// If not set, the default value is an empty string
  GlobalPrefix? _globalPrefix;

  /// The versioning options for the application
  VersioningOptions? get versioningOptions => _versioningOptions;

  /// The view engine for the application
  ViewEngine? get viewEngine => _viewEngine;

  /// Keep-alive idle timeout to apply to the underlying HTTP server.
  /// If null the adapter default will be used.
  final Duration? keepAliveIdleTimeout;

  /// The global prefix for the application
  GlobalPrefix? get globalPrefix => _globalPrefix;

  /// The base url for the application
  String get baseUrl =>
      '${securityContext != null ? 'https' : 'http'}://$host:$port';

  /// The error handler for the application
  /// This is used to handle errors that occur during the execution of the application
  ErrorHandler? errorHandler;

  /// The versioning options for the application
  set versioningOptions(VersioningOptions? value) {
    if (_versioningOptions != null) {
      throw StateError('Versioning options already set');
    }
    _versioningOptions = value;
  }

  /// The global prefix for the application
  set globalPrefix(GlobalPrefix? value) {
    if (_globalPrefix != null) {
      throw StateError('Global prefix already set');
    }
    _globalPrefix = value;
  }

  /// The view engine for the application
  set viewEngine(ViewEngine? value) {
    if (_viewEngine != null) {
      throw StateError('View engine already set');
    }
    _viewEngine = value;
  }

  /// The http adapter for the application
  final HttpAdapter serverAdapter;

  /// The adapters used by the application
  ///
  /// This is used to store the adapters used by the application
  /// E.g. [SseAdapter], [WsAdapter], etc.
  final AdapterContainer adapters = AdapterContainer();

  /// The [HooksContainer] for the application
  /// This is used to store the modules used by the application
  final HooksContainer globalHooks = HooksContainer();

  /// The [PipesContainer] for the application
  /// This is used to store the pipes used by the application
  final List<s.Pipe> globalPipes = [];

  /// The [ModulesContainer] for the application
  /// This is used to store the modules used by the application
  late final ModulesContainer modulesContainer;

  /// The model provider for the application
  final ModelProvider? modelProvider;

  /// The tracer for the application
  final TracersService tracerService = TracersService();

  /// The set of exception filters to be applied globally
  final Set<ExceptionFilter> globalExceptionFilters = {};

  /// Register a tracer to the application
  void registerTracer(Tracer tracer) {
    tracerService.registerTracer(tracer);
  }

  /// The application config constructor
  ApplicationConfig({
    required this.serverAdapter,
    this.modelProvider,
    this.keepAliveIdleTimeout,
  }) {
    adapters.add(serverAdapter);
  }
}

/// The configuration for a worker isolate in a clustered application. This class is used to configure the worker's HTTP server settings, logging options, and other relevant configurations that are necessary for the worker to function properly within the cluster. It allows for customization of the worker's behavior while still adhering to the overall configuration of the main application.
class WorkerConfig {
  /// The host to be used by the worker's HTTP server. Default is 'localhost'.
  final String host;
  /// The port to be used by the worker's HTTP server. Default is 3000.
  final int port;
  /// The header to be sent with the response. Default is 'Powered by Serinus'.
  final String poweredByHeader;
  /// The security context for the worker's HTTP server if any. If not provided, the worker will be created as a normal HTTP server. If provided, the worker will be created as a secure HTTPS server.
  final SecurityContext? securityContext;
  /// The model provider for the worker, which can be used to define how models are serialized and deserialized when communicating between workers in the cluster. This allows for consistent data handling across different worker isolates, ensuring that complex objects can be properly transmitted and reconstructed when sent between workers.
  final ModelProvider? modelProvider;
  /// If true, the worker's HTTP server will use compression for responses. This can help reduce the size of the response payloads and improve performance, especially for larger responses. Default is true.
  final bool enableCompression;
  /// If true, the worker's HTTP server will provide the raw request body as a stream. This can be useful for handling large request bodies or for processing the request body in a custom way. Default is false.
  final bool rawBody;
  /// The error handler for the worker, which can be used to handle errors that occur during the execution of the worker. This allows for custom error handling logic to be implemented for each worker in the cluster, providing flexibility in how errors are managed and responded to within the worker's context.
  final NotFoundHandler? notFoundHandler;
  /// The limit for the size of the request body that the worker's HTTP server will accept. This is used to prevent excessively large request bodies from being processed, which can help protect against certain types of attacks and improve the stability of the worker. Default is kDefaultMaxBodySize (which is typically set to a reasonable default value).
  final int bodySizeLimit;
  /// The set of log levels that the worker will use for logging. This allows for customization of the logging behavior for each worker in the cluster, enabling different log levels to be used for different workers based on their specific needs and roles within the application.
  final Set<LogLevel>? logLevels;
  /// The logger service to be used by the worker for logging. This allows for a consistent logging mechanism to be used across all workers in the cluster, and also allows for customization of the logging behavior for each worker if needed.
  final LoggerService? logger;

  /// The constructor for the [WorkerConfig] class initializes the worker configuration with the specified settings for the HTTP server, logging options, and other relevant configurations. This allows for easy creation of worker configurations that can be used when bootstrapping worker isolates in a clustered application, ensuring that each worker is properly configured to function within the cluster while still adhering to the overall configuration of the main application.
  WorkerConfig({
    this.host = 'localhost',
    this.port = 3000,
    this.logLevels,
    this.logger,
    this.poweredByHeader = 'Powered by Serinus',
    this.securityContext,
    this.modelProvider,
    this.enableCompression = true,
    this.rawBody = false,
    this.notFoundHandler,
    this.bodySizeLimit = kDefaultMaxBodySize,
  });

}