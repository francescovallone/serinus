import '../enums/http_method.dart';
import 'guard.dart';
import 'pipe.dart';

/// The [Route] class is used to define the routes of the application.
class Route {
  /// The path of the route.
  final String path;

  /// The HTTP method of the route.
  final HttpMethod method;

  /// The query parameters of the route.
  final Map<String, Type> queryParameters;

  /// The [guards] property contains the guards of the route.
  List<Guard> get guards => [];

  /// The [pipes] property contains the pipes of the route.
  List<Pipe> get pipes => [];

  /// The [version] property contains the version of the route.
  int? get version => null;

  /// The [Route] constructor is used to create a new instance of the [Route] class.
  const Route({
    required this.path,
    required this.method,
    this.queryParameters = const {},
  });

  /// The [Route.get] factory constructor is used to create a new instance of the [Route] class with the GET method.
  factory Route.get(String path) {
    return Route(path: path, method: HttpMethod.get);
  }

  /// The [Route.post] factory constructor is used to create a new instance of the [Route] class with the POST method.
  factory Route.post(String path) {
    return Route(path: path, method: HttpMethod.post);
  }

  /// The [Route.put] factory constructor is used to create a new instance of the [Route] class with the PUT method.
  factory Route.put(String path) {
    return Route(path: path, method: HttpMethod.put);
  }

  /// The [Route.delete] factory constructor is used to create a new instance of the [Route] class with the DELETE method.
  factory Route.delete(String path) {
    return Route(path: path, method: HttpMethod.delete);
  }

  /// The [Route.patch] factory constructor is used to create a new instance of the [Route] class with the PATCH method.
  factory Route.patch(String path) {
    return Route(path: path, method: HttpMethod.patch);
  }

}
