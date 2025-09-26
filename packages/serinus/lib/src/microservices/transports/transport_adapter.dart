import 'dart:typed_data';

import '../../adapters/adapters.dart';
import '../../contexts/contexts.dart';
import '../../core/core.dart';
import '../microservices_module.dart';
import 'transports.dart';

/// Base class for transport options.
abstract class TransportOptions {
  /// The [TransportOptions] constructor is used to create a new instance of the [TransportOptions] class.
  const TransportOptions(this.port);

  /// The port number for the transport.
  final int port;
}

/// Base class for a transport adapter (e.g. in-memory, Redis, NATS, etc.).
/// It provides unified APIs for request/response (RPC) and event (pub/sub) semantics.
abstract class TransportAdapter<TDriver, TOptions extends TransportOptions>
    extends Adapter<TDriver> {
  /// Unique name identifying this adapter (e.g. 'inmemory', 'redis').
  @override
  String get name;

  /// Router instance used to map incoming packets to handlers.
  Map<String, MessageHandler> requestResponseRouter = {};

  /// Router instance used to map incoming events to handlers.
  Map<String, List<EventHandler>> eventRouter = {};

  /// Define the transport options.
  final TOptions options;

  /// Constructor for the transport adapter.
  TransportAdapter(this.options);

  /// Initialize underlying driver resources.
  @override
  Future<void> init(ApplicationConfig config);

  /// Listen to the incoming packets and route them to the appropriate handlers.
  Future<void> listen();

  /// Send a fire-and-forget event.
  Future<void> emit(RpcContext context);

  /// Send an RPC style request and wait for a response (or timeout).
  Future<ResponsePacket> send(RpcContext context);

  /// Stream of transport status events (e.g. connected, disconnected, error).
  Stream<TransportEvent> get status;

  /// Messages resolver instance for this transport.
  /// It will be initialized after the bootstrap phase.
  MessagesResolver? messagesResolver;

  /// Get the messages resolver for this transport.
  MessagesResolver getResolver(ApplicationConfig config) {
    messagesResolver ??= DefaultMessagesResolver(config);
    return messagesResolver!;
  }
}

/// Wrapper class for a transport adapter instance.
class TransportInstance {
  /// The underlying transport adapter.
  final TransportAdapter _adapter;

  /// Constructor for the transport instance.
  TransportInstance(this._adapter);

  /// Stream of events from the underlying transport adapter.
  Stream<E> status<E extends TransportEvent>() => _adapter.status as Stream<E>;
}

/// Base class for transport client options.
abstract class TransportClientOptions {}

/// Base class for a transport client (e.g. in-memory, Redis, NATS, etc.).
abstract class TransportClient<T extends TransportClientOptions>
    extends Provider {
  /// The transport client options.
  final T options;

  /// Constructor for the transport client.
  TransportClient(this.options);

  /// Connect to the underlying transport.
  Future<void> connect();

  /// Disconnect from the underlying transport.
  Future<ResponsePacket?> send({
    required String pattern,
    required String id,
    Uint8List? payload,
  });

  /// Emit a fire-and-forget event.
  Future<void> emit({required String pattern, Uint8List? payload});
}
