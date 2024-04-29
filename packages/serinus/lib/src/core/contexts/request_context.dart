import 'package:serinus/serinus.dart';

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
  );

  T use<T>() {
    if (!providers.containsKey(T)) {
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }
}

class _RequestContextImpl extends RequestContext {
  _RequestContextImpl(super.providers, super.request);

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

  RequestContextBuilder();

  RequestContextBuilder addProviders(Iterable<Provider> providers) {
    this.providers.addAll({
      for (var provider in providers) provider.runtimeType: provider,
    });
    return this;
  }

  RequestContext build(Request request) {
    _context = _RequestContextImpl(providers, request);
    return _context!;
  }
}
