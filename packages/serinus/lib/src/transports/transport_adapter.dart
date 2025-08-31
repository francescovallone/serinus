import 'package:spanner/spanner.dart';

import '../adapters/adapters.dart';
import '../core/core.dart';
import 'transport_packets.dart';

/// Base class for a transport adapter (e.g. in-memory, Redis, NATS, etc.).
/// It provides unified APIs for request/response (RPC) and event (pub/sub) semantics.
abstract class TransportAdapter<TDriver> extends Adapter<TDriver> {
  /// Unique name identifying this adapter (e.g. 'inmemory', 'redis').
  @override
  String get name;

  /// Spanner instance for routing messages.
  Spanner get router;

  /// Initialize underlying driver resources.
  @override
  Future<void> init(ApplicationConfig config);

  /// Send a fire-and-forget event.
  Future<void> emit(EventPacket event);

  /// Send an RPC style request and wait for a response (or timeout).
  Future<ResponsePacket> send(RequestPacket request);

  /// Subscribe to patterns (exact match for MVP). Implementations may internally
  /// support wildcards but we will keep the initial contract simple.
  Future<void> subscribe(String pattern);

  /// Stream of all incoming packets (RequestPacket or EventPacket). Implementations
  /// wrap them into [IncomingMessagePacket] so the dispatcher can route generically.
  Stream<IncomingMessagePacket> get incoming;
}
