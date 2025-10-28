import 'package:meta/meta.dart';

import '../../adapters/sse_adapter.dart';
import '../core.dart';

/// The [SseEmitter] is responsible for dispatching SSE events to connected clients from other parts of the application.
class SseEmitter extends Provider {
  final SseAdapter _adapter;

  /// The list of connected clients.
  Iterable<String?> get clients => _adapter.connections.keys;

  /// The constructor for [SseEmitter].
  SseEmitter(this._adapter);

  /// This method is used to send data to the client.
  /// The [data] parameter is the data to be sent.
  @nonVirtual
  void send(String data, {String? clientId}) {
    _adapter.send(data, clientId);
  }
}
