import 'package:uuid/uuid.dart';

import '../../../serinus.dart';
import '../../containers/injection_token.dart';
import '../../extensions/string_extensions.dart';
import '../../inspector/entrypoint.dart';
import 'route_info_path_extractor.dart';

/// Registers middleware for the application.
class MiddlewareRegistry extends Provider with OnApplicationBootstrap {
  final ApplicationConfig _config;

  final RouteInfoPathExtractor _pathExtractor;

  final GraphInspector _inspector;

  final Map<InjectionToken, Set<MiddlewareConfiguration>>
  _middlewareConfigurations = {};

  final Map<String, Set<MiddlewareConfiguration>> _middlewareByRoute = {};

  /// Creates a new instance of [MiddlewareRegistry].
  MiddlewareRegistry(this._config, this._pathExtractor, this._inspector);

  @override
  Future<void> onApplicationBootstrap() async {
    await _resolveMiddleware();
    await _mapMiddlewareToRoutes();
  }

  Future<void> _resolveMiddleware() async {
    for (final scope in _config.modulesContainer.scopes) {
      await _loadMiddlewareConfiguration(scope.token, scope.module);
    }
    _addToGraph();
  }

  void _addToGraph() {
    final middlewareConfigurations =
        <MapEntry<InjectionToken, MiddlewareConfiguration>>{};
    for (final entry in _middlewareConfigurations.entries) {
      for (final configuration in entry.value) {
        middlewareConfigurations.add(MapEntry(entry.key, configuration));
      }
    }
    for (final middlewareConfiguration in middlewareConfigurations) {
      final controllers = <Controller>[];
      final routes = <RouteInfo>{...middlewareConfiguration.value.routes};
      for (final scope in _config.modulesContainer.scopes) {
        controllers.addAll(
          scope.controllers.where(
            (controller) =>
                middlewareConfiguration.value.controllers.contains(
                  controller.runtimeType,
                ) ||
                middlewareConfiguration.value.controllers.isEmpty,
          ),
        );
      }
      for (final controller in controllers) {
        routes.addAll(
          controller.routes.entries.map(
            (e) => RouteInfo(
              '${controller.path.stripEndSlash()}${e.value.route.path}'
                  .stripEndSlash()
                  .addLeadingSlash(),
              method: e.value.route.method,
              versions: [
                if (e.value.route.version != null)
                  VersioningOptions.uri(version: e.value.route.version!),
                if (controller.version != null)
                  VersioningOptions.uri(version: controller.version!),
                if (_config.versioningOptions != null)
                  _config.versioningOptions!,
              ],
            ),
          ),
        );
        if (controller is SseController) {
          routes.addAll(
            controller.sseRoutes.entries.map(
              (e) => RouteInfo(
                '${controller.path.stripEndSlash()}${e.value.route.path}'
                    .stripEndSlash()
                    .addLeadingSlash(),
                method: e.value.route.method,
                versions: [
                  if (e.value.route.version != null)
                    VersioningOptions.uri(version: e.value.route.version!),
                  if (controller.version != null)
                    VersioningOptions.uri(version: controller.version!),
                  if (_config.versioningOptions != null)
                    _config.versioningOptions!,
                ],
              ),
            ),
          );
        }
      }
      routes.removeWhere(
        (route) => middlewareConfiguration.value.excludedRoutes.any(
          (excludeRoute) => _canResolve(route, excludeRoute),
        ),
      );
      for (final middleware in middlewareConfiguration.value.middlewares) {
        _inspector.graph.insertNode(
          ClassNode(
            id: InjectionToken.fromType(middleware.runtimeType),
            label: middleware.runtimeType.toString(),
            parent: middlewareConfiguration.key,
            metadata: ClassMetadataNode(
              type: InjectableType.middleware,
              sourceModuleName: middlewareConfiguration.key,
            ),
          ),
        );
        for (final route in routes) {
          _inspector.graph.insertEntrypoint(
            Entrypoint(
              type: EntrypointType.middleware,
              className: middleware.runtimeType.toString(),
              id: Uuid().v4(),
              metadata: EntrypointMetadata(
                key: route.path,
                path: route.path,
                requestMethod: route.method.name,
                versions:
                    route.versions
                        ?.map((version) => version.version)
                        .toList() ??
                    [],
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadMiddlewareConfiguration(
    InjectionToken moduleToken,
    Module module,
  ) async {
    final middlewareConsumer = MiddlewareConsumer(_pathExtractor);
    try {
      module.configure(middlewareConsumer);
    } catch (e) {
      throw InitializationError(
        'Failed to configure middlewares for module: ${module.token}',
      );
    }
    _middlewareConfigurations[moduleToken] = middlewareConsumer.configurations;
  }

  Future<void> _mapMiddlewareToRoutes() async {
    final entriesSortedByDistance = [...(_middlewareConfigurations.entries)]
      ..sort((entryA, entryB) {
        final scopeA = _config.modulesContainer.getScope(entryA.key);
        final scopeB = _config.modulesContainer.getScope(entryB.key);
        if (scopeA.module.isGlobal && scopeB.module.isGlobal) {
          return 0;
        }
        if (scopeA.module.isGlobal) {
          return -1;
        }
        if (scopeB.module.isGlobal) {
          return 1;
        }
        return (scopeA.distance - scopeB.distance).toInt();
      });
    for (final entry in entriesSortedByDistance) {
      await _registerAllConfigs(entry.value);
    }
    for (final scope in _config.modulesContainer.scopes) {
      for (final route in _middlewareByRoute.keys) {
        scope.setRouteMiddlewares(route, (request, context) {
          final requestRouteInfo = RouteInfo(
            request.uri.path.stripEndSlash().addLeadingSlash(),
            method: HttpMethod.parse(request.method),
            versions: [
              if (context.spec.route.version != null)
                VersioningOptions.uri(version: context.spec.route.version!),
              if (context.controller.version != null)
                VersioningOptions.uri(version: context.controller.version!),
              if (_config.versioningOptions != null) _config.versioningOptions!,
            ],
          );
          return _middlewareByRoute[route]
                  ?.where((configuration) {
                    return (configuration.routes.any(
                          (routeInfo) =>
                              _canResolve(requestRouteInfo, routeInfo),
                        )) &&
                        !configuration.excludedRoutes.any(
                          (excludeRoute) =>
                              _canResolve(requestRouteInfo, excludeRoute),
                        );
                  })
                  .map((configuration) => configuration.middlewares)
                  .expand((m) => m)
                  .toList() ??
              <Middleware>[];
        });
      }
    }
  }

  Future<void> _registerAllConfigs(
    Set<MiddlewareConfiguration> configuration,
  ) async {
    final controllers = <({Controller controller, ModuleScope scope})>[];
    for (final scope in _config.modulesContainer.scopes) {
      controllers.addAll(
        scope.module.controllers.map(
          (controller) => (controller: controller, scope: scope),
        ),
      );
    }
    final routesToControllers =
        <
          ({
            String id,
            String path,
            HttpMethod method,
            Controller controller,
            int? version,
            ModuleScope scope,
          })
        >[];
    for (final (:controller, :scope) in controllers) {
      final controllerRoutes = controller.routes;
      for (final route in controllerRoutes.entries) {
        routesToControllers.add((
          scope: scope,
          id: route.key,
          controller: controller,
          version: route.value.route.version ?? controller.version,
          path: '${controller.path}${route.value.route.path}'.stripEndSlash(),
          method: route.value.route.method,
        ));
      }
      if (controller is SseController) {
        for (final route in controllerRoutes.entries) {
          routesToControllers.add((
            scope: scope,
            id: route.key,
            controller: controller,
            version: route.value.route.version ?? controller.version,
            path: '${controller.path}${route.value.route.path}'.stripEndSlash(),
            method: route.value.route.method,
          ));
        }
      }
    }
    final includedRoutes =
        <
          ({
            Controller controller,
            String id,
            HttpMethod method,
            String path,
            int? version,
            ModuleScope scope,
          })
        >{};
    for (final config in configuration) {
      includedRoutes.addAll(
        routesToControllers.where(
          (c) => config.controllers.any(
            (spec) => spec == c.controller.runtimeType,
          ),
        ),
      );
      for (final route in routesToControllers) {
        final (:id, :path, :method, :version, :controller, :scope) = route;
        final currentRouteInfo = RouteInfo(
          path.replaceAll('//', '/'),
          method: method,
          versions: [
            if (version != null) VersioningOptions.uri(version: version),
            if (controller.version != null)
              VersioningOptions.uri(version: controller.version!),
            if (_config.versioningOptions != null) _config.versioningOptions!,
          ],
        );

        // Check if route matches any configuration route
        final isIncluded =
            config.routes.any(
              (routeInfo) => _canResolve(currentRouteInfo, routeInfo),
            ) ||
            config.controllers.any((spec) => spec == controller.runtimeType);
        // Check if route is excluded
        final isExcluded = config.excludedRoutes.any(
          (excludeRoute) => _canResolve(currentRouteInfo, excludeRoute),
        );
        if (isIncluded && !isExcluded) {
          config.routes.add(currentRouteInfo);
          includedRoutes.add(route);
        }
      }
      for (final routes in includedRoutes) {
        _middlewareByRoute[routes.id] = {
          ...(_middlewareByRoute[routes.id] ?? []),
          config,
        };
      }
    }
  }

  /// Checks if [target] can be resolved by [resolver] based on path, method, and versions
  bool _canResolve(RouteInfo target, RouteInfo resolver) {
    // Method must match exactly
    if ((target.method != resolver.method) &&
        (resolver.method != HttpMethod.all &&
            target.method != HttpMethod.all)) {
      return false;
    }
    // Check path compatibility
    if (!_pathsMatch(target.path, resolver.path)) {
      return false;
    }

    // Check version compatibility
    return _versionsMatch(target.versions, resolver.versions);
  }

  /// Checks if two paths match, considering parametric routes
  bool _pathsMatch(String targetPath, String resolverPath) {
    // Exact match
    if (targetPath == resolverPath) {
      return true;
    }

    // Check if resolver path is parametric and can match target
    final parametricRegex = RegExp(r'<[^>]+>');

    if (resolverPath.contains('<')) {
      // Convert parametric path to regex pattern
      final pattern = resolverPath.replaceAll(parametricRegex, r'([^/]+)');
      final regex = RegExp('^$pattern\$');
      return regex.hasMatch(targetPath);
    }

    // Check if target path is parametric and can match resolver
    if (targetPath.contains('<')) {
      final pattern = targetPath.replaceAll(parametricRegex, r'([^/]+)');
      final regex = RegExp('^$pattern\$');
      return regex.hasMatch(resolverPath);
    }

    return false;
  }

  /// Checks if versions are compatible
  bool _versionsMatch(
    List<VersioningOptions>? targetVersions,
    List<VersioningOptions>? resolverVersions,
  ) {
    // If both are null, they match (both are unversioned)
    if (targetVersions == null && resolverVersions == null) {
      return true;
    }
    // If resolver is null, it matches any target version (resolver is unversioned, applies to all)
    if (resolverVersions == null) {
      return true;
    }
    // If target is null but resolver has versions, no match (target is unversioned but resolver is version-specific)
    if (targetVersions == null) {
      return false;
    }
    // If resolver versions is empty, it matches any target version
    if (resolverVersions.isEmpty) {
      return true;
    }
    // If target versions is empty but resolver has versions, no match
    if (targetVersions.isEmpty) {
      return false;
    }
    // Check if there's any intersection between the version lists
    final targetVersionNumbers = targetVersions.map((v) => v.version).toSet();
    final resolverVersionNumbers =
        resolverVersions.map((v) => v.version).toSet();

    return targetVersionNumbers.intersection(resolverVersionNumbers).isNotEmpty;
  }

  /// Retrieves the middlewares for a specific route.
  List<Middleware> getRouteMiddlewares(String path) {
    final middlewares = _middlewareByRoute.values.expand((e) => e);
    final requestRouteInfo = RouteInfo(path.stripEndSlash().addLeadingSlash());
    return middlewares
        .where((configuration) {
          return configuration.routes.any(
                (routeInfo) => _canResolve(requestRouteInfo, routeInfo),
              ) &&
              !configuration.excludedRoutes.any(
                (excludeRoute) => _canResolve(requestRouteInfo, excludeRoute),
              );
        })
        .map((configuration) => configuration.middlewares)
        .expand((m) => m)
        .toList();
  }
}
