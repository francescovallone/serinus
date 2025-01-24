import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_sse/src/sse_context.dart';
import 'package:serinus_sse/src/sse_handler.dart';
import 'package:serinus_sse/src/sse_provider.dart';
import 'package:stream_channel/stream_channel.dart';

typedef InitializedChannel = ({
  StreamChannel<List<int>> channel,
  StringConversionSink sink
});

class SseAdapter extends HttpAdapter<StreamQueue<SseConnection>> {

  final _connections = <String?, SseConnection>{};
  final _connectionController = StreamController<SseConnection>();

  bool hasConnection(String clientId) => _connections.containsKey(clientId);

  final Map<Type, SseContext> _contexts = {};

  StreamQueue<SseConnection>? _connectionsStream;

  StreamQueue<SseConnection> get connections =>
      _connectionsStream ?? StreamQueue(_connectionController.stream);

  HttpServer? connection;

  bool _isOpen = false;

  final Duration? keepAlive;

  final Future<void> Function(HttpRequest request)? fallback;

  @override
  bool get isOpen => _isOpen;

  SseAdapter({this.keepAlive, this.fallback})
      : super(host: 'localhost', poweredByHeader: 'Powerd by Serinus', port: 3000);

  @override
  Future<void> init(
      ModulesContainer container, ApplicationConfig config) async {
    server = StreamQueue<SseConnection>(_connectionController.stream);
    _isOpen = true;
  }

  Future<void> acceptReconnection(String clientId, StringConversionSink sink) async {
    final connection = _connections[clientId];
    if (connection == null) {
      return;
    }
    connection._acceptReconnection(sink);
  }

  void addConnection(String clientId, SseConnection connection) {
    _connections[clientId] = connection;
  }

  void addConnectionController(SseConnection connection) {
    _connectionController.add(connection);
  }

  Future<StringConversionSink> initializeChannel(
      InternalRequest req) async {
    final socket = await req.response.detachSocket();
    final channel = StreamChannel<List<int>>(socket, socket);
    final origin = (req.headers['origin'] ?? req.headers['host']);
    final sink = utf8.encoder.startChunkedConversion(channel.sink)
      ..add('HTTP/1.1 200 OK\r\n'
          'Content-Type: text/event-stream\r\n'
          'Cache-Control: no-cache\r\n'
          'Connection: keep-alive\r\n'
          'Access-Control-Allow-Credentials: true\r\n'
          "${origin != null ? 'Access-Control-Allow-Origin: $origin\r\n' : ''}"
          '\r\n');
    return sink;
  }

  @override
  Future<void> close() async {
    if (server == null) {
      return;
    }
    connection?.close(force: true);
    _isOpen = false;
  }

  @override
  Future<void> listen(RequestCallback requestCallback,
      {dynamic request, ErrorHandler? errorHandler}) async {
    return;
  }

  @override
  bool get shouldBeInitilized => true;

  @override
  bool canHandle(InternalRequest request) {
    return request.headers['accept'] == 'text/event-stream' &&
        (request.method == 'GET' || request.method == 'POST');
  }

  Future<void> addIncomingMessage(InternalRequest req, InternalResponse res,
      String clientId, List<SseProvider> providers) async {
    final connection = _connections[clientId];
    if (connection == null) {
      throw BadRequestException(
          message: 'Cannot handle incoming message. Connection not found.');
    }
    final id = int.parse(req.queryParameters['messageId'] ?? '-1');
    final message = await req.body();
    try {
      connection._addIncomingMessage(id, message);
      for (final provider in providers) {
        provider.onMessage(
            clientId, message, _contexts[provider.runtimeType]!);
      }
    } catch (_) {
      throw BadRequestException(
          message: 'Cannot handle incoming message. Invalid message format.');
    }
    res.headers({
      'access-control-allow-credentials': 'true',
      'access-control-allow-origin':
          (req.headers['origin'] ?? req.headers['host'] ?? '*')
    });
    res.status(200);
    res.flushAndClose();
  }

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

  void addContext(Type type, SseContext context) {
    _contexts[type] = context;
  }

  @override
  Handler getHandler(ModulesContainer container, ApplicationConfig config, Router router) {
    return SseHandler(router, container, config);
  }
}

/// Code entirely copied from https://raw.githubusercontent.com/dart-lang/sse/master/lib/src/server/sse_handler.dart
/// I wanted to use the [SseConnection] with my implementation of the Sse Handler but it was not possible because the
/// method [_addIncomingMessage] is private. So I copied the whole code to be able to use it.

class _SseMessage {
  final int id;
  final String message;
  _SseMessage(this.id, this.message);
}

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

  /// The id of the last processed incoming message.
  int _lastProcessedId = -1;

  /// Incoming messages that have yet to be processed.
  final _pendingMessages =
      HeapPriorityQueue<_SseMessage>((a, b) => a.id.compareTo(b.id));

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
    while (
        !_outgoingController.isClosed && await _outgoingStreamQueue.hasNext) {
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
      if (_closedCompleter.isCompleted) break;

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
  void _addIncomingMessage(int id, String message) {
    _pendingMessages.add(_SseMessage(id, message));
    while (_pendingMessages.isNotEmpty) {
      var pendingMessage = _pendingMessages.first;
      // Only process the next incremental message.
      if (pendingMessage.id - _lastProcessedId <= 1) {
        _incomingController.sink.add(pendingMessage.message);
        _lastProcessedId = pendingMessage.id;
        _pendingMessages.removeFirst();
      } else {
        // A message came out of order. Wait until we receive the previous
        // messages to process.
        break;
      }
    }
  }

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
      _keepAliveTimer = Timer(_keepAlive ?? Duration.zero, _close);
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
      if (!_incomingController.isClosed) _incomingController.close();
    }
  }

  /// Immediately close the connection, ignoring any keepAlive period.
  void shutdown() {
    _close();
  }
}
