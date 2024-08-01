import '../adapters/adapters.dart';
import '../core/websockets/websockets.dart';
import '../http/http.dart';
import 'base_context.dart';

/// The [WebSocketContext] class is used to create a WebSocket context.
///
/// It contains the request, the WebSocket adapter, the ID of the context, the providers, and the serializer.
final class WebSocketContext extends BaseContext {
  /// The [request] property contains the request of the context.
  final Request request;

  final WsAdapter _wsAdapter;

  /// The [id] property contains the id of the client.
  final String id;

  final MessageSerializer? _serializer;

  /// The [queryParamters] property contains the query parameters of the request.
  Map<String, dynamic> get query => request.query;

  /// The [headers] property contains the headers of the request.
  Map<String, dynamic> get headers => request.headers;

  /// The constructor of the [WebSocketContext] class.
  const WebSocketContext(this._wsAdapter, this.id, super.providers,
      this.request, this._serializer);

  /// This method is used to send data to the client.
  ///
  /// The [data] parameter is the data to be sent.
  ///
  /// The [broadcast] parameter is used to broadcast the data to all clients.
  void send(dynamic data) {
    if (_serializer != null) {
      data = _serializer!.serialize(data);
    }
    _wsAdapter.send(data, key: id);
  }

  /// This method is used to broadcast data to all clients.
  ///
  /// The [data] parameter is the data to be sent.
  void broadcast(dynamic data) {
    if (_serializer != null) {
      data = _serializer!.serialize(data);
    }
    _wsAdapter.send(data);
  }
}
