import '../contexts/request_context.dart';
import '../enums/http_method.dart';
import 'metadata.dart';

/// The [Route] class is used to define the routes of the application.
class Route {
  /// The path of the route.
  final String path;

  /// The HTTP method of the route.
  final HttpMethod method;

  /// The query parameters of the route.
  final Map<String, Type> queryParameters;

  /// The [version] property contains the version of the route.
  int? get version => null;

  /// The [Route] constructor is used to create a new instance of the [Route] class.
  const Route({
    required this.path,
    required this.method,
    this.queryParameters = const {},
    this.metadata = const [],
  });

  /// The [metadata] getter is used to get the List of [Metadata] of the route.
  final List<Metadata> metadata;

  /// The [transform] method is used to transform the request context.
  ///
  /// It can be overridden if needed.
  Future<void> transform(RequestContext context) async {}

  /// The [beforeHandle] method is used to execute code before the route is handled.
  ///
  /// It can be overridden if needed.
  Future<void> beforeHandle(RequestContext context) async {}

  /// The [afterHandle] method is used to execute code after the route is handled.
  ///
  /// It can be overridden if needed.
  Future<void> afterHandle(RequestContext context, dynamic response) async {}

  /// The [Route.get] factory constructor is used to create a new instance of the [Route] class with the GET method.
  factory Route.get(String path, {List<Metadata> metadata = const []}) {
    return Route(path: path, method: HttpMethod.get, metadata: metadata);
  }

  /// The [Route.post] factory constructor is used to create a new instance of the [Route] class with the POST method.
  factory Route.post(String path, {List<Metadata> metadata = const []}) {
    return Route(path: path, method: HttpMethod.post, metadata: metadata);
  }

  /// The [Route.put] factory constructor is used to create a new instance of the [Route] class with the PUT method.
  factory Route.put(String path, {List<Metadata> metadata = const []}) {
    return Route(path: path, method: HttpMethod.put, metadata: metadata);
  }

  /// The [Route.delete] factory constructor is used to create a new instance of the [Route] class with the DELETE method.
  factory Route.delete(String path, {List<Metadata> metadata = const []}) {
    return Route(path: path, method: HttpMethod.delete, metadata: metadata);
  }

  /// The [Route.patch] factory constructor is used to create a new instance of the [Route] class with the PATCH method.
  factory Route.patch(String path, {List<Metadata> metadata = const []}) {
    return Route(path: path, method: HttpMethod.patch, metadata: metadata);
  }
}
