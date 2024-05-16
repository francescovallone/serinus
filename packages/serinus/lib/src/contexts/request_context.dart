import '../core/core.dart';
import '../http/http.dart';

sealed class RequestContext {
  final Map<Type, Provider> providers;
  final Request request;
  late final Body body;

  String get path => request.path;

  Map<String, dynamic> get headers => request.headers;

  void addDataToRequest(String key, dynamic value) {
    request.addData(key, value);
  }

  Map<String, dynamic> get pathParameters => request.params;

  Map<String, dynamic> get queryParameters => request.queryParameters;

  RequestContext(
    this.providers,
    this.request,
    this.body,
  );

  T use<T>() {
    if (!providers.containsKey(T)) {
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }
}

class _RequestContextImpl extends RequestContext {
  _RequestContextImpl(super.providers, super.request, super.body);

  @override
  T use<T>() {
    if (!providers.containsKey(T)) {
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }
}

class RequestContextBuilder {
  RequestContext? _context;

  Map<Type, Provider> providers = {};

  RequestContextBuilder({
    this.providers = const {},
  });

  RequestContext build(Request request, Body body) {
    _context = _RequestContextImpl(providers, request, body);
    return _context!;
  }
}
