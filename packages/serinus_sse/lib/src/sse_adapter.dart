import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_sse/src/sse_context.dart';
import 'package:serinus_sse/src/sse_mixins.dart';
import 'package:serinus_sse/src/sse_provider.dart';
import 'package:stream_channel/stream_channel.dart';

typedef InitializedChannel = ({
  StreamChannel<List<int>> channel, 
  StringConversionSink sink
});

class SseAdapter extends HttpAdapter<StreamQueue<SseConnection>> {

  Logger logger = Logger('SseAdapter');

  final _connections = <String?, SseConnection>{};
  final _connectionController = StreamController<SseConnection>();

  final Map<Type, SseContext> _contexts = {};

  StreamQueue<SseConnection>? _connectionsStream;

  StreamQueue<SseConnection> get connections => _connectionsStream ?? StreamQueue(_connectionController.stream);

  HttpServer? connection;

  bool _isOpen = false;

  final Duration? keepAlive;

  final Future<void> Function(HttpRequest request)? fallback;
  
  @override
  bool get isOpen => _isOpen;

  SseAdapter({required super.port, this.keepAlive, this.fallback}) : super(host: 'localhost', poweredByHeader: 'Powerd by Serinus');

  @override
  Future<void> init(ModulesContainer container, ApplicationConfig config) async {
    server = StreamQueue<SseConnection>(_connectionController.stream);
    _prepareContexts(container, config);
    connection = await HttpServer.bind(InternetAddress.loopbackIPv4, port, shared: true);
    logger.info('SSE server is running on port $port');
    connection?.listen((req) => _handleConnection(req, container, config));
    _isOpen = true;
  }

  Future<void> _handleConnection(HttpRequest request, ModulesContainer container, ApplicationConfig config) async {
    final req = InternalRequest.from(request);
    final providers = container.getAll<SseProvider>();
    final clientId = req.queryParameters['sseClientId'];
    if(req.method == 'GET' && req.headers['accept'] == 'text/event-stream') {
      if (clientId == null) {
        request.response.statusCode = 400;
        request.response.close();
        return;
      }
      _initializeChannel(
        request,
        (channel, sink) {
          if(_connections.containsKey(clientId)) {
            _connections[clientId]?._acceptReconnection(sink);
          } else {
            final connection = SseConnection(sink, keepAlive: keepAlive);
            _connections[clientId] = connection;
            _connectionController.add(connection);
          }
          providers.whereType<OnSseConnect>().forEach((e) => e.onConnect(clientId));
        }
      );
    }
    if(req.method == 'POST' && req.headers['accept'] == 'text/event-stream') {
      if (clientId == null) {
        request.response.statusCode = 400;
        request.response.close();
        return;
      }
      _addIncomingMessage(request, req, clientId, providers);
    }
    if(fallback != null) {
      await fallback!(request);
    }
  }

  Future<void> _initializeChannel(
    HttpRequest req,
    void Function(StreamChannel<List<int>> channel, StringConversionSink sink) onChannel
  ) async {
    final socket = await req.response.detachSocket(writeHeaders: false);
    final channel = StreamChannel<List<int>>(socket, socket);
    final origin = (req.headers['origin'] ?? req.headers['host'])?.join(', ');
    final sink = utf8.encoder.startChunkedConversion(channel.sink)
      ..add('HTTP/1.1 200 OK\r\n'
          'Content-Type: text/event-stream\r\n'
          'Cache-Control: no-cache\r\n'
          'Connection: keep-alive\r\n'
          'Access-Control-Allow-Credentials: true\r\n'
          "${origin != null ? 'Access-Control-Allow-Origin: $origin\r\n' : ''}"
          '\r\n');
    onChannel(channel, sink);
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
    return request.headers['accept'] == 'text/event-stream' && (request.method == 'GET' || request.method == 'POST');
  }
  
  Future<void> _addIncomingMessage(
    HttpRequest httpReq, 
    InternalRequest req, 
    String clientId,
    List<SseProvider> providers
  ) async {
    final connection = _connections[clientId];
    if (connection == null) {
      httpReq.response.statusCode = 404;
      httpReq.response.close();
      return;
    }
    final id = int.parse(req.queryParameters['messageId'] ?? '-1');
    final message = await req.body();
    try{
      connection._addIncomingMessage(id, message);
      for(final provider in providers) {
        provider.onResponse(
          clientId, 
          message, 
          _contexts[provider.runtimeType]!
        );
      }
    }catch(_) {
      logger.error('{$clientId} Cannot handle incoming message: $id');
    }
    httpReq.response.headers.add('access-control-allow-credentials', true);
    httpReq.response.headers.add('access-control-allow-origin', (req.headers['origin'] ?? req.headers['host']));
    httpReq.response.statusCode = 200;
    httpReq.response.close();
  }

  void send(String data, [String? clientId]) {
    if(clientId != null) {
      final connection = _connections[clientId];
      if (connection == null) {
        logger.error('Cannot send message to $clientId. Connection not found.');
        return;
      }
      connection.sink.add(data);
      return;
    }
    for (final connection in _connections.values) {
      connection.sink.add(data);
    }
  }
  
  void _prepareContexts(ModulesContainer container, ApplicationConfig config) {
    final providers = container.getAll<SseProvider>();
    for (final provider in providers) {
      final providerModule =
          container.getModuleByProvider(provider.runtimeType);
      final injectables = container.getModuleInjectablesByToken(
          container.moduleToken(providerModule));
      final scopedProviders = List<Provider>.from(injectables.providers
          .addAllIfAbsent(container.globalProviders));
      scopedProviders.remove(provider);
      final context = SseContext(
        (config.adapters[SseAdapter] as SseAdapter?)!,
        {
          for (final provider in scopedProviders)
            provider.runtimeType: provider
        }
      );
      _contexts[provider.runtimeType] = context;
    }
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