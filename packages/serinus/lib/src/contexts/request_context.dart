import '../core/core.dart';
import '../http/http.dart';

/// The [RequestContext] class is used to create the request context.
sealed class RequestContext {
  /// The [providers] property contains the providers of the request context.
  final Map<Type, Provider> providers;

  /// The [request] property contains the request of the context.
  final Request request;

  /// The [body] property contains the body of the context.
  late final Body body;

  /// The [path] property contains the path of the request.
  String get path => request.path;

  /// The [method] property contains the method of the request.
  Map<String, dynamic> get headers => request.headers;

  /// The [addDataToRequest] method is used to add data to the request.
  void addDataToRequest(String key, dynamic value) {
    request.addData(key, value);
  }

  /// The [pathParameters] property contains the path parameters of the request.
  Map<String, dynamic> get pathParameters => request.params;

  /// The [queryParameters] property contains the query parameters of the request.
  Map<String, dynamic> get queryParameters => request.queryParameters;

  RequestContext(
    this.providers,
    this.request,
    this.body,
  );

  /// This method is used to retrieve a provider from the context.
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

/// The [RequestContextBuilder] class is used to create the request context builder.
final class RequestContextBuilder {
  RequestContext? _context;

  /// The [providers] property contains the providers of the request context.
  final Map<Type, Provider> providers;

  /// The [RequestContextBuilder] constructor is used to create a new instance of the [RequestContextBuilder] class.
  RequestContextBuilder({
    this.providers = const {},
  });

  /// The [build] method is used to build the request context.
  RequestContext build(Request request, Body body) {
    _context = _RequestContextImpl(providers, request, body);
    return _context!;
  }
}
