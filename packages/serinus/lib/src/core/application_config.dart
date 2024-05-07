import 'dart:io';

import 'package:uuid/v4.dart';

import '../adapters/server_adapter.dart';
import '../engines/view_engine.dart';
import '../global_prefix.dart';
import '../http/cors.dart';
import '../versioning.dart';

/// The configuration for the application
/// This is used to configure the application
final class ApplicationConfig {
  /// The host to be used by the application
  /// Default is 'localhost'
  ///
  /// This can be changed to any value
  final String host;

  /// The port to be used by the application
  /// Default is 3000
  ///
  /// This can be changed to any value
  final int port;

  /// The header to be sent with the response
  /// Default is 'Powered by Serinus'
  /// This can be changed to any value
  final String poweredByHeader;

  /// The security context for the application if any
  /// If not provided, the application will be created as a normal http server
  /// If provided, the application will be created as a secure https server
  final SecurityContext? securityContext;

  /// The applicationId, every application has a unique id
  final String applicationId = UuidV4().generate();

  /// The versioning options for the application
  /// This can be set using the [enableVersioning] method
  /// The versioning options can be set only once
  /// If the versioning options are already set, a [StateError] will be thrown
  VersioningOptions? _versioningOptions;

  /// The cors options for the application
  /// This can be set using the [enableCors] method
  /// The cors options can be set only once
  /// If the cors options are already set, a [StateError] will be thrown
  Cors? _cors;

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

  VersioningOptions? get versioningOptions => _versioningOptions;

  Cors? get cors => _cors;

  ViewEngine? get viewEngine => _viewEngine;

  GlobalPrefix? get globalPrefix => _globalPrefix;

  String get baseUrl =>
      '${securityContext != null ? 'https' : 'http'}://$host:$port';

  set versioningOptions(VersioningOptions? value) {
    if (_versioningOptions != null) {
      throw StateError('Versioning options already set');
    }
    _versioningOptions = value;
  }

  set globalPrefix(GlobalPrefix? value) {
    if (_globalPrefix != null) {
      throw StateError('Global prefix already set');
    }
    _globalPrefix = value;
  }

  set cors(Cors? value) {
    if (_cors != null) {
      throw StateError('Cors options already set');
    }
    _cors = value;
  }

  set viewEngine(ViewEngine? value) {
    if (_viewEngine != null) {
      throw StateError('View engine already set');
    }
    _viewEngine = value;
  }

  final Adapter serverAdapter;

  ApplicationConfig({
    required this.host,
    required this.port,
    required this.poweredByHeader,
    required this.serverAdapter,
    this.securityContext,
  });
}
