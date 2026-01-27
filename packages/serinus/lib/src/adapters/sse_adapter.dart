import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:uuid/v4.dart';

import '../containers/hooks_container.dart';
import '../contexts/contexts.dart';
import '../core/core.dart';
import '../core/middlewares/middleware_executor.dart';
import '../enums/http_method.dart';
import '../exceptions/exceptions.dart';
import '../extensions/object_extensions.dart';
import '../http/http.dart';
import '../router/atlas.dart';
import '../utils/wrapped_response.dart';
import 'adapters.dart';

/// The [SseScope] class is used to define the scope of a Server-Sent Events (SSE) gateway.
/// It contains the [SseRouteSpec], the providers, and the hooks.
class SseScope {
  /// The [gateway] property contains the WebSocket gateway.
  final SseRouteHandlerSpec sseRouteSpec;

  /// The [providers] property contains the providers of the WebSocket gateway.
  final Map<Type, Provider> providers;

  /// The [hooks] property contains the hooks of the WebSocket gateway.
  final HooksContainer hooks;

  /// The [metadata] property contains the metadata of the WebSocket gateway.
  final List<Metadata> metadata;

  /// The [middlewares] property contains the middlewares of the WebSocket gateway.
  final Iterable<Middleware> Function(IncomingMessage request) middlewares;

  /// The [GatewayScope] constructor is used to create a new instance of the [GatewayScope] class.
  const SseScope(
    this.sseRouteSpec,
    this.providers,
    this.hooks,
    this.metadata,
    this.middlewares,
  );

  @override
  String toString() {
    return 'GatewayScope(gateway: $sseRouteSpec, providers: $providers)';
  }
}

/// The [SseAdapter] class is used to create a new Server-Sent Events (SSE) adapter.
class SseAdapter extends Adapter<StreamQueue<SseConnection>> {
  final _connections = <String?, SseConnection>{};
  final _connectionController = StreamController<SseConnection>();

  /// The [httpAdapter] property contains the underlying http adapter of the application.
  final HttpAdapter httpAdapter;

  /// The [router] property contains the router used by the SSE adapter.
  final Atlas router = Atlas();

  /// The [connections] property contains the active SSE connections.
  Map<String?, SseConnection> get connections =>
      UnmodifiableMapView(_connections);

  bool _isOpen = false;

  /// The [keepAlive] property contains the duration for which the SSE connection should be kept alive.
  final Duration? keepAlive;

  @override
  bool get isOpen => _isOpen;

  /// Creates a new instance of [SseAdapter].
  SseAdapter(this.httpAdapter, {this.keepAlive});

  @override
  Future<void> init(ApplicationConfig config) async {
    server = StreamQueue<SseConnection>(_connectionController.stream);
    httpAdapter.events.listen((event) async {
      if (event.type == ServerEventType.custom) {
        final SseEventData eventData = event.data as SseEventData;
        await start(eventData.request, eventData.response);
      }
    });
    _isOpen = true;
  }

  /// Accepts a reconnection request from a client.
  Future<void> acceptReconnection(
    String clientId,
    StringConversionSink sink,
  ) async {
    final connection = _connections[clientId];
    if (connection == null) {
      return;
    }
    connection._acceptReconnection(sink);
  }

  /// Adds a new SSE connection for a client.
  void addConnection(String clientId, SseConnection connection) {
    _connections[clientId] = connection;
  }

  /// Adds the SSE connection to the connection controller.
  void addConnectionController(SseConnection connection) {
    _connectionController.add(connection);
  }

  /// Starts the SSE connection.
  Future<void> start(IncomingMessage request, OutgoingMessage response) async {
    final route = router.lookup(HttpMethod.get, request.path);
    if (route is NotFoundRoute) {
      final exception =
          httpAdapter.notFoundHandler?.call(Request(request)) ??
          NotFoundException(
            'No SSE route found for ${request.method} ${request.path}',
          );
      await httpAdapter.reply(
        response,
        request,
        WrappedResponse(jsonEncode(exception.toJson()).toBytes()),
        ResponseContext({}, {})
          ..headers.addAll({'content-type': 'application/json'})
          ..statusCode = exception.statusCode,
      );
      return;
    }
    final currentScope = route.values.firstOrNull as SseScope?;
    if (currentScope == null) {
      final exception =
          httpAdapter.notFoundHandler?.call(Request(request)) ??
          NotFoundException(
            'No SSE route found for ${request.method} ${request.path}',
          );
      await httpAdapter.reply(
        response,
        request,
        WrappedResponse(jsonEncode(exception.toJson()).toBytes()),
        ResponseContext({}, {})
          ..headers.addAll({'content-type': 'application/json'})
          ..statusCode = exception.statusCode,
      );
      return;
    }
    final wrappedRequest = Request(request, route.params);
    final clientId =
        wrappedRequest.query['sseClientId'] ??
        wrappedRequest.cookies
            .firstWhereOrNull((c) => c.name == 'sseClientId')
            ?.value ??
        UuidV4().generate();
    final sink = await upgrade(request, response);
    final executionContext = ExecutionContext(
      HostType.sse,
      currentScope.providers,
      currentScope.hooks.services,
      SseArgumentsHost(wrappedRequest, clientId),
    );
    for (final hook in currentScope.hooks.reqHooks) {
      await hook.onRequest(executionContext);
    }
    executionContext.metadata.addAll(
      await initMetadata(executionContext, currentScope.metadata),
    );
    executionContext.response.addCookie(
      Cookie('sseClientId', clientId)
        ..httpOnly = true
        ..path = '/',
    );
    final middlewares = currentScope.middlewares(request);
    if (middlewares.isNotEmpty) {
      final executor = MiddlewareExecutor();
      await executor.execute(
        middlewares,
        executionContext,
        response,
        onDataReceived: (data) async {
          if (_connections.containsKey(clientId)) {
            final connection = _connections[clientId];
            connection?.shutdown();
          }
        },
      );
      if (response.isClosed) {
        return;
      }
    }
    for (final hook in currentScope.hooks.beforeHooks) {
      await hook.beforeHandle(executionContext);
    }
    final sseContext = executionContext.switchToSse();
    if (_connections.containsKey(clientId)) {
      await acceptReconnection(clientId, sink);
      final result = currentScope.sseRouteSpec.handler.call(sseContext);
      final connection = _connections[clientId];
      result.listen((data) {
        connection!.sink.add(data);
      });
      return;
    }
    final connection = SseConnection(sink, keepAlive: keepAlive);
    addConnection(clientId, connection);
    addConnectionController(connection);
    final result = currentScope.sseRouteSpec.handler.call(sseContext);
    result.listen((data) {
      connection.sink.add(data);
    });
    connection._closedCompleter.future.whenComplete(() async {
      _connections.remove(clientId);
      for (final hook in currentScope.hooks.afterHooks) {
        await hook.afterHandle(executionContext, WrappedResponse(null));
      }
      for (final hook in currentScope.hooks.resHooks) {
        await hook.onResponse(executionContext, WrappedResponse(null));
      }
    });
  }

  /// Upgrades the HTTP connection to a SSE connection.
  Future<StringConversionSink> upgrade(
    IncomingMessage req,
    OutgoingMessage res,
  ) async {
    final socket = await res.detachSocket();
    final channel = StreamChannel<List<int>>(socket, socket);
    final origin = (req.headers['origin'] ?? req.headers['host']);
    final sink = utf8.encoder.startChunkedConversion(channel.sink)
      ..add(
        'HTTP/1.1 200 OK\r\n'
        'Content-Type: text/event-stream\r\n'
        'Cache-Control: no-cache\r\n'
        'Connection: keep-alive\r\n'
        'Access-Control-Allow-Credentials: true\r\n'
        "${origin != null ? 'Access-Control-Allow-Origin: $origin\r\n' : ''}"
        '\r\n',
      );
    return sink;
  }

  @override
  Future<void> close() async {
    if (server == null) {
      return;
    }
    for (final connection in _connections.values) {
      connection.shutdown();
    }
    _isOpen = false;
  }

  /// Sends a message to a specific client or broadcasts it to all clients.
  void send(String data, [String? clientId]) {
    if (clientId != null) {
      final connection = _connections[clientId];
      if (connection == null) {
        return;
      }
      connection.sink.add(data);
      return;
    }
    for (final connection in _connections.values) {
      connection.sink.add(data);
    }
  }

  /// Initializes the metadata for the SSE connection.
  Future<Map<String, Metadata>> initMetadata(
    ExecutionContext context,
    List<Metadata> metadata,
  ) async {
    final result = <String, Metadata>{};
    for (final meta in metadata) {
      if (meta is ContextualizedMetadata) {
        result[meta.name] = await meta.resolve(context);
      } else {
        result[meta.name] = meta;
      }
    }
    return result;
  }

  @override
  String get name => 'sse';
}

/// Code entirely copied from https://raw.githubusercontent.com/dart-lang/sse/master/lib/src/server/sse_handler.dart
/// I wanted to use the [SseConnection] with my implementation of the Sse Handler but it was not possible because the
/// method [_addIncomingMessage] is private. So I copied the whole code to be able to use it.

// class _SseMessage {
//   final int id;
//   final String message;
//   _SseMessage(this.id, this.message);
// }

/// A bi-directional SSE connection between server and browser.
class SseConnection extends StreamChannelMixin<String> {
  /// Incoming messages from the Browser client.
  final _incomingController = StreamController<String>();

  /// Outgoing messages to the Browser client.
  final _outgoingController = StreamController<String>();

  Sink _sink;

  /// How long to wait after a connection drops before considering it closed.
  final Duration? _keepAlive;

  /// A timer counting down the KeepAlive period (null if hasn't disconnected).
  Timer? _keepAliveTimer;

  /// Whether this connection is currently in the KeepAlive timeout period.
  bool get isInKeepAlivePeriod => _keepAliveTimer?.isActive ?? false;

  // /// The id of the last processed incoming message.
  // int _lastProcessedId = -1;

  // /// Incoming messages that have yet to be processed.
  // final _pendingMessages =
  //     HeapPriorityQueue<_SseMessage>((a, b) => a.id.compareTo(b.id));

  final _closedCompleter = Completer<void>();

  /// Wraps the `_outgoingController.stream` to buffer events to enable keep
  /// alive.
  late StreamQueue _outgoingStreamQueue;

  /// Creates an [SseConnection] for the supplied [_sink].
  ///
  /// If [keepAlive] is supplied, the connection will remain active for this
  /// period after a disconnect and can be reconnected transparently. If there
  /// is no reconnect within that period, the connection will be closed
  /// normally.
  ///
  /// If [keepAlive] is not supplied, the connection will be closed immediately
  /// after a disconnect.
  SseConnection(this._sink, {Duration? keepAlive}) : _keepAlive = keepAlive {
    _outgoingStreamQueue = StreamQueue(_outgoingController.stream);
    unawaited(_setUpListener());
    _outgoingController.onCancel = _close;
    _incomingController.onCancel = _close;
  }

  Future<void> _setUpListener() async {
    while (!_outgoingController.isClosed &&
        await _outgoingStreamQueue.hasNext) {
      // If we're in a KeepAlive timeout, there's nowhere to send messages so
      // wait a short period and check again.
      if (isInKeepAlivePeriod) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        continue;
      }

      // Peek the data so we don't remove it from the stream if we're unable to
      // send it.
      final data = await _outgoingStreamQueue.peek;

      // Ignore outgoing messages since the connection may have closed while
      // waiting for the keep alive.
      if (_closedCompleter.isCompleted) {
        break;
      }

      try {
        // JSON encode the message to escape new lines.
        _sink.add('data: ${json.encode(data)}\n');
        _sink.add('\n');
        await _outgoingStreamQueue.next; // Consume from stream if no errors.
      } catch (e) {
        if ((e is StateError || e is SocketException) &&
            (_keepAlive != null && !_closedCompleter.isCompleted)) {
          // If we got here then the sink may have closed but the stream.onDone
          // hasn't fired yet, so pause the subscription and skip calling
          // `next` so the message remains in the queue to try again.
          _handleDisconnect();
        } else {
          rethrow;
        }
      }
    }
  }

  /// The message added to the sink has to be JSON encodable.
  @override
  StreamSink<String> get sink => _outgoingController.sink;

  // Add messages to this [StreamSink] to send them to the server.
  /// [Stream] of messages sent from the server to this client.
  ///
  /// A message is a decoded JSON object.
  @override
  Stream<String> get stream => _incomingController.stream;

  /// Adds an incoming [message] to the [stream].
  ///
  /// This will buffer messages to guarantee order.
  // void _addIncomingMessage(int id, String message) {
  //   _pendingMessages.add(_SseMessage(id, message));
  //   while (_pendingMessages.isNotEmpty) {
  //     var pendingMessage = _pendingMessages.first;
  //     // Only process the next incremental message.
  //     if (pendingMessage.id - _lastProcessedId <= 1) {
  //       _incomingController.sink.add(pendingMessage.message);
  //       _lastProcessedId = pendingMessage.id;
  //       _pendingMessages.removeFirst();
  //     } else {
  //       // A message came out of order. Wait until we receive the previous
  //       // messages to process.
  //       break;
  //     }
  //   }
  // }

  void _acceptReconnection(Sink sink) {
    _keepAliveTimer?.cancel();
    _sink = sink;
  }

  void _handleDisconnect() {
    if (_keepAlive == null) {
      // Close immediately if we're not keeping alive.
      _close();
    } else if (!isInKeepAlivePeriod && !_closedCompleter.isCompleted) {
      // Otherwise if we didn't already have an active timer and we've not
      // already been completely closed, set a timer to close after the timeout
      // period.
      // If the connection comes back, this will be cancelled and all messages
      // left in the queue tried again.
      _keepAliveTimer = Timer(_keepAlive, _close);
    }
  }

  void _close() {
    if (!_closedCompleter.isCompleted) {
      _closedCompleter.complete();
      // Cancel any existing timer in case we were told to explicitly shut down
      // to avoid keeping the process alive.
      _keepAliveTimer?.cancel();
      _sink.close();
      if (!_outgoingController.isClosed) {
        _outgoingStreamQueue.cancel(immediate: true);
        _outgoingController.close();
      }
      if (!_incomingController.isClosed) {
        _incomingController.close();
      }
    }
  }

  /// Immediately close the connection, ignoring any keepAlive period.
  void shutdown() {
    _close();
  }
}
