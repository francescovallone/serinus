import '../../serinus.dart';

/// The [HandlerFunction] is a function that handles the incoming request and returns a response.
typedef HandlerFunction =
    Future<void> Function(
      IncomingMessage request,
      OutgoingMessage response,
      Map<String, dynamic> params,
    );

/// The [RouteContext] class is used to store the context of a route.
class RouteContext<T extends RouteHandlerSpec> {
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
  final T spec;

  /// The [moduleScope] is used to store the scope of the module.
  final ModuleScope moduleScope;

  /// The [providers] property contains the providers of the module.
  late final Map<Type, Provider> providers = {
    for (var provider in moduleScope.unifiedProviders)
      provider.runtimeType: provider,
  };

  /// The [values] property contains the values from ValueProviders.
  late final Map<ValueToken, Object?> values = Map.unmodifiable(
    moduleScope.unifiedValues,
  );

  /// Internal cache for metadata defined at controller and route level.
  late final List<Metadata> _metadataCache = [
    ...controller.metadata,
    ...spec.route.metadata,
  ];

  /// Cached metadata entries that do not require runtime resolution.
  late final Map<String, Metadata> _staticMetadata = {
    for (final meta in _metadataCache.where(
      (m) => m is! ContextualizedMetadata,
    ))
      meta.name: meta,
  };

  late final Map<String, Metadata> _staticMetadataView = Map.unmodifiable(
    _staticMetadata,
  );

  late final bool _hasContextualMetadata =
      _metadataCache.length != _staticMetadata.length;

  /// The [metadata] is used to store the metadata for the route.
  List<Metadata> get metadata => _metadataCache;

  /// The [exceptionFilters] of the route.
  final Set<ExceptionFilter> exceptionFilters;

  /// The list of pipes to be applied.
  final List<Pipe> pipes;

  /// The [hooksServices] is used to store the services for the hooks.
  final Map<Type, Object> hooksServices;

  /// The [hooksContainer] is used to store the hooks for the route.
  final HooksContainer hooksContainer;

  /// Immutable snapshots of hooks taken at route registration time.
  /// Using these avoids per-request iteration and any accidental mutation.
  late final List<OnRequest> reqHooks = List.unmodifiable(
    hooksContainer.reqHooks,
  );

  /// The [beforeHooks] is used to store the before hooks for the route.
  late final List<OnBeforeHandle> beforeHooks = List.unmodifiable(
    hooksContainer.beforeHooks,
  );

  /// The [afterHooks] is used to store the after hooks for the route.
  late final List<OnAfterHandle> afterHooks = List.unmodifiable(
    hooksContainer.afterHooks,
  );

  /// The [resHooks] is used to store the response hooks for the route.
  late final List<OnResponse> resHooks = List.unmodifiable(
    hooksContainer.resHooks,
  );

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
    this.pipes = const [],
    this.queryParameters = const {},
    this.hooksServices = const {},
    this.exceptionFilters = const {},
  });

  /// Initializes the metadata for the route context.
  Future<Map<String, Metadata>> initMetadata(ExecutionContext context) async {
    if (!_hasContextualMetadata) {
      return _staticMetadataView;
    }
    final resolved = <String, Metadata>{..._staticMetadata};
    for (int i = 0; i < _metadataCache.length; i++) {
      final meta = _metadataCache[i];
      if (meta is ContextualizedMetadata) {
        resolved[meta.name] = await meta.resolve(context);
      }
    }
    return resolved;
  }

  /// Returns the middlewares for the route.
  Iterable<Middleware> getMiddlewares(IncomingMessage message) {
    return moduleScope.getRouteMiddlewares(id, message, this);
  }
}
