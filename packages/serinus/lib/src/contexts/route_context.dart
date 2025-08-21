import '../../serinus.dart';
import '../containers/hooks_container.dart';
import '../containers/injection_token.dart';

/// The [HandlerFunction] is a function that handles the incoming request and returns a response.
typedef HandlerFunction = Future<void> Function(
  IncomingMessage request,
  OutgoingMessage response,
  Map<String, dynamic> params,
);

/// The [RouteContext] class is used to store the context of a route.
class RouteContext {
  
  /// The [id] is used to uniquely identify the route.
  final String id;

  /// The [path] is used to store the path of the route.
  final String path;

  /// The [HttpMethod] of the route.
  final HttpMethod method;

  /// The [controller] is used to store the controller that handles the route.
  final Controller controller;

  /// The [routeCls] is used to store the class of the route.
  final Type routeCls;

  /// The [moduleToken] is used to identify the module that the route belongs to.
  final InjectionToken moduleToken;

  /// The [queryParameters] is used to store the query parameters for the route.
  final Map<String, Type> queryParameters;

  /// The [isStatic] is used to determine if the route is static or not.
  final bool isStatic;

  /// The [spec] is used to store the route specification.
  final RouteHandler spec;

  /// The [moduleScope] is used to store the scope of the module.
  final ModuleScope moduleScope;

  /// The [schema] is used to store the schema for the route.
  ParseSchema? get schema => spec.schema;

  /// The [metadata] is used to store the metadata for the route.
  List<Metadata> get metadata => [
    ...controller.metadata,
    ...spec.route.metadata,
  ];

  /// The [hooksServices] is used to store the services for the hooks.
  final Map<Type, Object> hooksServices;

  /// The [hooksContainer] is used to store the hooks for the route.
  final HooksContainer hooksContainer;

  /// The [RouteContext] constructor initializes the route context with the provided parameters.
  RouteContext({
    required this.id,
    required this.path,
    required this.method,
    required this.controller,
    required this.routeCls,
    required this.moduleToken,
    required this.spec,
    required this.moduleScope,
    required this.hooksContainer,
    this.isStatic = false,
    this.queryParameters = const {},
    this.hooksServices = const {},
  });

  /// Initializes the metadata for the route context.
  Future<Map<String, Metadata>> initMetadata(RequestContext context) async {
    final result = <String, Metadata>{};
    for (final meta in metadata) {
      if (meta is ContextualizedMetadata) {
        result[meta.name] = await meta.resolve(context);
      } else {
        result[meta.name] = meta;
      }
    }
    return result;
  }

  /// Returns the middlewares for the route.
  Iterable<Middleware> getMiddlewares(IncomingMessage message) {
    return moduleScope.getRouteMiddlewares(id, message);
  }

}