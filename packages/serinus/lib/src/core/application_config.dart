import 'dart:io';

import 'package:uuid/v4.dart';

import '../adapters/adapters.dart';
import '../containers/adapter_container.dart';
import '../containers/hooks_container.dart';
import '../containers/model_provider.dart';
import '../containers/module_container.dart';
import '../engines/view_engine.dart';
import '../global_prefix.dart';
import '../microservices/transports/transports.dart';
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

  /// Maximum requests accepted per connection before the connection is closed.
  /// If null the adapter default will be used.
  final int maxRequestsPerConnection;

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
    this.maxRequestsPerConnection = 100,
  }) {
    adapters.add(serverAdapter);
  }
}
