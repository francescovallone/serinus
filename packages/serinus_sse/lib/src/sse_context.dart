import 'package:serinus/serinus.dart';

import 'sse_adapter.dart';

class SseContext extends BaseContext {
  final SseAdapter _adapter;

  SseContext(this._adapter, super.providers);

  /// This method is used to send data to the client.
  ///
  /// The [data] parameter is the data to be sent.
  ///
  /// The [broadcast] parameter is used to broadcast the data to all clients.
  void send(String data, String clientId) {
    _adapter.send(data, clientId);
  }

  /// This method is used to broadcast data to all clients.
  ///
  /// The [data] parameter is the data to be sent.
  void broadcast(String data) {
    _adapter.send(data);
  }
}
