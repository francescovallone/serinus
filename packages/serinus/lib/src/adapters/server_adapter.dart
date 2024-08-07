import 'dart:async';

import '../containers/module_container.dart';
import '../core/core.dart';
import '../http/internal_request.dart';
import '../http/internal_response.dart';

/// The [RequestCallback] type is used to define the request callback.
typedef RequestCallback = Future<void> Function(
    InternalRequest request, InternalResponse response);

/// The [ErrorHandler] type is used to define the error handler.
typedef ErrorHandler = void Function(dynamic e, StackTrace stackTrace);

/// The [Adapter] class is used to create a new adapter.
abstract class Adapter<TServer> {
  /// The [Adapter] constructor is used to create a new instance of the [Adapter] class.
  Adapter();

  /// The [server] property contains the server.
  TServer? server;

  /// The [isOpen] property contains the status of the adapter.
  bool get isOpen;

  /// If true the application will also initialize the adapter.
  bool get shouldBeInitilized;

  /// The [canHandle] method is used to determine if the adapter can handle the request.
  bool canHandle(InternalRequest request) => true;

  /// The [init] method is used to initialize the server.
  Future<void> init(ModulesContainer container, ApplicationConfig config);

  /// The [close] method is used to close the server.
  Future<void> close();

  /// The [listen] method is used to listen for requests.
  Future<void> listen(
    covariant dynamic requestCallback, {
    InternalRequest request,
    ErrorHandler? errorHandler,
  });
}
