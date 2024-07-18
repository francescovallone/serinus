import '../core/core.dart';
import '../http/http.dart';
import 'base_context.dart';

/// The [RequestContext] class is used to create the request context.
final class RequestContext extends BaseContext {
  /// The [request] property contains the request of the context.
  final Request request;

  /// The [body] property contains the body of the context.
  Body get body => request.body ?? Body.empty();

  /// The [path] property contains the path of the request.
  String get path => request.path;

  /// The [method] property contains the method of the request.
  Map<String, dynamic> get headers => request.headers;

  /// The [operator []] is used to get data from the request.
  dynamic operator [](String key) => request[key];

  /// The [operator []=] is used to set data to the request.
  void operator []=(String key, dynamic value) {
    request[key] = value;
  }

  /// The [params] property contains the path parameters of the request.
  Map<String, dynamic> get params => request.params;

  /// The [queryParameters] property contains the query parameters of the request.
  Map<String, dynamic> get query => request.query;

  /// The constructor of the [RequestContext] class.
  RequestContext(
    super.providers,
    this.request,
  );

  /// The [metadata] property contains the metadata of the request context.
  ///
  /// It is used to store metadata that is resolved at runtime.
  late final Map<String, Metadata> metadata;

  /// The [stat] method is used to retrieve a metadata from the context.
  T stat<T>(String name) {
    if (!canStat(name)) {
      throw StateError('Metadata $name not found in request context');
    }
    return metadata[name]!.value as T;
  }

  /// The [canStat] method is used to check if a metadata exists in the context.
  bool canStat(String name) {
    return metadata.containsKey(name);
  }
}
