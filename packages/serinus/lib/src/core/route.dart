import '../containers/hooks_container.dart';
import '../enums/http_method.dart';
import 'core.dart';

/// The [Route] class is used to define the routes of the application.
class Route {
  /// The path of the route.
  final String path;

  /// The HTTP method of the route.
  final HttpMethod method;

  /// The [version] property contains the version of the route.
  int? get version => null;

  /// The [Route] constructor is used to create a new instance of the [Route] class.
  Route({
    required this.path,
    required this.method,
    this.metadata = const [],
    this.pipes = const {},
    this.exceptionFilters = const {},
  }) {
    if (method == HttpMethod.all && path.contains('<')) {
      throw ArgumentError('"ALL" route cannot contain path parameters');
    }
  }

  /// The [metadata] getter is used to get the List of [Metadata] of the route.
  final List<Metadata> metadata;

  /// Container of the Route hooks.
  final HooksContainer hooks = HooksContainer();

  /// Set of exception filters to be applied to this route.
  final Set<ExceptionFilter> exceptionFilters;

  /// Set of pipes to be applied to this route.
  final Set<Pipe> pipes;

  /// The [Route.get] factory constructor is used to create a new instance of the [Route] class with the GET method.
  factory Route.get(
    String path, {
    List<Metadata> metadata = const [],
    Set<Pipe> pipes = const {},
    Set<ExceptionFilter> exceptionFilters = const {},
  }) {
    return Route(
      path: path,
      method: HttpMethod.get,
      metadata: metadata,
      pipes: pipes,
      exceptionFilters: exceptionFilters,
    );
  }

  /// The [Route.post] factory constructor is used to create a new instance of the [Route] class with the POST method.
  factory Route.post(
    String path, {
    List<Metadata> metadata = const [],
    Set<Pipe> pipes = const {},
    Set<ExceptionFilter> exceptionFilters = const {},
  }) {
    return Route(
      path: path,
      method: HttpMethod.post,
      metadata: metadata,
      pipes: pipes,
      exceptionFilters: exceptionFilters,
    );
  }

  /// The [Route.put] factory constructor is used to create a new instance of the [Route] class with the PUT method.
  factory Route.put(
    String path, {
    List<Metadata> metadata = const [],
    Set<Pipe> pipes = const {},
    Set<ExceptionFilter> exceptionFilters = const {},
  }) {
    return Route(
      path: path,
      method: HttpMethod.put,
      metadata: metadata,
      pipes: pipes,
      exceptionFilters: exceptionFilters,
    );
  }

  /// The [Route.delete] factory constructor is used to create a new instance of the [Route] class with the DELETE method.
  factory Route.delete(
    String path, {
    List<Metadata> metadata = const [],
    Set<Pipe> pipes = const {},
    Set<ExceptionFilter> exceptionFilters = const {},
  }) {
    return Route(
      path: path,
      method: HttpMethod.delete,
      metadata: metadata,
      pipes: pipes,
      exceptionFilters: exceptionFilters,
    );
  }

  /// The [Route.patch] factory constructor is used to create a new instance of the [Route] class with the PATCH method.
  factory Route.patch(
    String path, {
    List<Metadata> metadata = const [],
    Set<Pipe> pipes = const {},
    Set<ExceptionFilter> exceptionFilters = const {},
  }) {
    return Route(
      path: path,
      method: HttpMethod.patch,
      metadata: metadata,
      pipes: pipes,
      exceptionFilters: exceptionFilters,
    );
  }

  /// The [Route.all] factory constructor is used to create a new instance of the [Route] class with the ALL method.
  factory Route.all(
    String path, {
    List<Metadata> metadata = const [],
    Set<Pipe> pipes = const {},
    Set<ExceptionFilter> exceptionFilters = const {},
  }) {
    if (path.contains('<')) {
      throw ArgumentError('"ALL" route cannot contain path parameters');
    }
    return Route(
      path: path,
      method: HttpMethod.all,
      metadata: metadata,
      pipes: pipes,
      exceptionFilters: exceptionFilters,
    );
  }
}

/// Route for RPC style communication over a transporter.
class RpcRoute extends Route {
  /// The [RpcRoute] constructor is used to create a new instance of the [RpcRoute] class.
  RpcRoute({
    required String pattern,
    super.metadata = const [],
    this.transporter,
    super.pipes = const {},
    super.exceptionFilters = const {},
  }) : super(path: pattern, method: HttpMethod.get);

  /// Specify the transporter to use for this route.
  final Type? transporter;
}
