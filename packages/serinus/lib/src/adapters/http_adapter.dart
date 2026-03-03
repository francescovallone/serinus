import 'dart:async';
import 'dart:io';

import '../contexts/contexts.dart';
import '../core/core.dart';
import '../engines/view_engine.dart';
import '../http/server_event.dart';
import '../utils/wrapped_response.dart';
import 'server_adapter.dart';

/// The [HttpAdapter] class is used to create an HTTP server adapter.
///
/// It extends the [Adapter] class and allows the developer to define the host, port, and powered by header.
///
/// The class must be extended and the [init], [close], and [listen] methods must be implemented.
///
/// Properties:
/// - [host]: The host of the server.
/// - [port]: The port of the server.
/// - [poweredByHeader]: The powered by header.
abstract class HttpAdapter<TServer, TRequest, TResponse>
    extends Adapter<TServer> {
  /// The [host] property contains the host of the server.
  final String host;

  /// The [port] property contains the port of the server.
  final int port;

  /// The [poweredByHeader] property contains the powered by header.
  final String? poweredByHeader;

  /// The [securityContext] property contains the security context of the server.
  final SecurityContext? securityContext;

  /// The [preserveHeaderCase] property determines whether the header case should be preserved.
  /// If set to true, the header case will be preserved.
  final bool preserveHeaderCase;

  /// The [viewEngine] property contains the view engine of the server.
  ViewEngine? viewEngine;

  /// The [notFoundHandler] property contains the handler for not found routes.
  /// It is used to handle requests that do not match any defined route.
  NotFoundHandler? notFoundHandler;

  /// The [rawBody] property determines if the body will be treated as raw data or if the framework should try to parse it.
  /// By default, it is set to false, meaning the framework will try to parse the body.
  bool rawBody;

  final StreamController<ServerEvent> _eventsController =
      StreamController<ServerEvent>.broadcast();

  /// The [events] property is a stream of [ServerEvent] that allows listening to server events.
  Stream<ServerEvent> get events => _eventsController.stream;

  /// You can emit a [ServerEvent] to the stream.
  /// This can be used to notify listeners about server events such as request handling, errors, and more.
  void emit(ServerEvent event) {
    _eventsController.add(event);
  }

  /// The [HttpAdapter] constructor is used to create a new instance of the [HttpAdapter] class.
  HttpAdapter({
    required this.host,
    required this.port,
    this.poweredByHeader,
    this.securityContext,
    this.preserveHeaderCase = true,
    this.viewEngine,
    this.notFoundHandler,
    this.rawBody = false,
  });

  @override
  Future<void> init(ApplicationConfig config);

  @override
  Future<void> close();

  /// The [listen] method is used to start listening for incoming requests.
  /// It takes the [onRequest] callback to handle incoming requests and an optional [onError] callback to handle errors.
  Future<void> listen({
    required RequestCallback<TRequest, TResponse> onRequest,
    ErrorHandler? onError,
  });

  /// The [reply] method is used to send a response to the client.
  /// It takes the [response], [body], [context], and [config] as parameters.
  Future<void> reply(
    TResponse response,
    TRequest request,
    WrappedResponse body,
    ResponseContext properties,
  );

  /// The [redirect] method is used to redirect the client to a different URL.
  /// It takes the [response] and [redirect] as parameters.
  Future<void> redirect(
    TResponse response,
    Redirect redirect,
    ResponseContext properties,
  );

  /// The [render] method is used to render a view and send it as a response.
  /// It takes the [response], [view], and [properties] as parameters.
  Future<void> render(
    TResponse response,
    View view,
    ResponseContext properties,
  );
}

/// The [NoopAdapter] class is a no-operation implementation of the [HttpAdapter] class.
class NoopAdapter extends HttpAdapter<void, void, void> {
  @override
  String get name => 'noop';

  /// The [NoopAdapter] constructor is used to create a new instance of the [NoopAdapter] class.
  NoopAdapter() : super(host: 'localhost', port: 0);

  @override
  Future<void> close() {
    return Future.value();
  }

  @override
  Future<void> init(ApplicationConfig config) {
    return Future.value();
  }

  @override
  Future<void> listen({
    required RequestCallback<void, void> onRequest,
    ErrorHandler? onError,
  }) {
    return Future.value();
  }

  @override
  Future<void> redirect(
    void response,
    Redirect redirect,
    ResponseContext properties,
  ) {
    return Future.value();
  }

  @override
  Future<void> reply(
    void response,
    void request,
    WrappedResponse body,
    ResponseContext properties,
  ) {
    return Future.value();
  }

  @override
  Future<void> render(void response, View view, ResponseContext properties) {
    return Future.value();
  }

  @override
  bool get isOpen => true;
}
