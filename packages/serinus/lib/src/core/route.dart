import '../contexts/request_context.dart';
import '../enums/http_method.dart';

/// The [Route] class is used to define the routes of the application.
abstract class Route {
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
  });

  /// The [transform] method is used to transform the request context.
  ///
  /// It can be overridden if needed.
  Future<void> transform(RequestContext context) async {}

  /// The [parse] method is used to parse and validate the request context.
  ///
  /// It can be overridden if needed.
  Future<void> parse(RequestContext context) async {}

  /// The [beforeHandle] method is used to execute code before the route is handled.
  /// 
  /// It can be overridden if needed.
  Future<void> beforeHandle(RequestContext context) async {}

  /// The [afterHandle] method is used to execute code after the route is handled.
  /// 
  /// It can be overridden if needed.
  Future<void> afterHandle(RequestContext context) async {}

}
