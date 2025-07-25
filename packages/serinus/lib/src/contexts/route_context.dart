import '../../serinus.dart';
import '../containers/hooks_container.dart';
import '../containers/injection_token.dart';

class RouteContext {

  final String id;

  final String path;

  final HttpMethod method;

  final Controller controller;

  final Type routeCls;

  final InjectionToken moduleToken;

  final Map<String, Type> queryParameters;

  final bool isStatic;

  final RouteHandler spec;

  final ModuleScope moduleScope;

  ParseSchema? get schema => spec.schema;

  List<Metadata> get metadata => [
    ...controller.metadata,
    ...spec.route.metadata,
  ];


  final Map<Type, Object> hooksServices;

  final HooksContainer hooksContainer;

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

  Set<Middleware> getMiddlewares(Map<String, dynamic> params) {
    return moduleScope.filterMiddlewaresByRoute(path, params);
  }

}


class RouteExecutionContext {

  final Function resolver;

  final RouteContext routeContext;

  RouteExecutionContext({
    required this.resolver,
    required this.routeContext,
  });

}