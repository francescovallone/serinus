import 'dart:async';

import '../../serinus.dart';

/// The [RequestCallback] type is used to define the request callback.
typedef RequestCallback = Future<void> Function(
    Request request, InternalResponse response);

/// The [ErrorHandler] type is used to define the error handler.
typedef ErrorHandler = Object? Function(dynamic e, StackTrace stackTrace);

/// The [NotFoundHandler] type is used to define the not found handler.
typedef NotFoundHandler = SerinusException? Function();

/// The [Adapter] class is used to create a new adapter.
abstract class Adapter<TServer> {

  /// The [name] property contains the name of the adapter.
  /// The name is used to identify the adapter in the application and also to understand the type of request that is being handled.
  String get name;

  /// The [Adapter] constructor is used to create a new instance of the [Adapter] class.
  Adapter();

  /// The [server] property contains the server.
  TServer? server;

  /// The [isOpen] property contains the status of the adapter.
  bool get isOpen;

  /// If true the application will also initialize the adapter.
  bool get shouldBeInitilized;

  /// The [init] method is used to initialize the server.
  Future<void> init(ModulesContainer container, ApplicationConfig config);

  /// The [close] method is used to close the server.
  Future<void> close();

  /// The [listen] method is used to listen for requests.
  Future<void> listen(
    {
      required RequestCallback onRequest,
      ErrorHandler? onError,
    }
  );

}
