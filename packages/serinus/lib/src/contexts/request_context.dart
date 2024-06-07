import '../core/core.dart';
import '../http/http.dart';

/// The [RequestContext] class is used to create the request context.
final class RequestContext {
  /// The [providers] property contains the providers of the request context.
  final Map<Type, Provider> providers;

  /// The [request] property contains the request of the context.
  final Request request;

  /// The [body] property contains the body of the context.
  Body get body => request.body ?? Body.empty();

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
  );

  /// This method is used to retrieve a provider from the context.
  T use<T>() {
    if (!providers.containsKey(T)) {
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }
}
