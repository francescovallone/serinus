import '../../../serinus.dart';

class WebSocketContext {
  final Request request;

  final WsAdapter _wsAdapter;

  final String id;

  final Map<Type, Provider> _providers;

  final MessageSerializer? _serializer;

  Map<String, dynamic> get queryParameters => request.queryParameters;

  Map<String, dynamic> get headers => request.headers;

  WebSocketContext(this._wsAdapter, this.id, this._providers, this.request, this._serializer);

  void send(dynamic data, {bool broadcast = false}) {
    if (_serializer != null) {
      data = _serializer!.serialize(data);
    }
    _wsAdapter.send(data, broadcast: broadcast, key: id);
  }

  T use<T>() {
    if (!_providers.containsKey(T)) {
      throw StateError('Provider not found in request context');
    }
    return _providers[T] as T;
  }
}
