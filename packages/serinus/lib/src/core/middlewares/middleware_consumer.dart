import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../../../serinus.dart';
import '../../extensions/string_extensions.dart';
import 'route_info_path_extractor.dart';

final class MiddlewareConfiguration {

  final List<Middleware> middlewares;

  final List<RouteInfo> routes;

  final List<RouteInfo> excludedRoutes;

  final List<Type> controllers;

  MiddlewareConfiguration({
    required this.middlewares,
    required this.routes,
    required this.excludedRoutes,
    required this.controllers,
  });

  MiddlewareConfiguration copyWith({
    List<Middleware>? middlewares,
    List<RouteInfo>? routes,
    List<RouteInfo>? excludedRoutes,
    List<Type>? controllers,
  }) {
    return MiddlewareConfiguration(
      middlewares: middlewares ?? this.middlewares,
      routes: routes ?? this.routes,
      excludedRoutes: excludedRoutes ?? this.excludedRoutes,
      controllers: controllers ?? this.controllers,
    );
  }
}

final class RouteInfo {

  final String path;

  final HttpMethod method;

  final List<VersioningOptions>? versions;

  const RouteInfo({
    required this.path,
    this.method = HttpMethod.all,
    this.versions,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RouteInfo &&
        other.path == path &&
        other.method == method &&
        ListEquality<VersioningOptions>().equals(other.versions, versions);
  }

  @override
  int get hashCode => Object.hash(path, method, versions);
}

class MiddlewareConsumer {
  
  final Map<String, MiddlewareConfiguration> _configurations = {};

  Set<MiddlewareConfiguration> get configurations => {..._configurations.values};

  List<Middleware>? _middlewares;

  String? _currentIteration;

  final RouteInfoPathExtractor _pathExtractor;

  MiddlewareConsumer(this._pathExtractor);

  MiddlewareConsumer apply(List<Middleware> middlewares) {
    if(middlewares.isEmpty) {
      throw ArgumentError('Middlewares cannot be empty');
    }
    _middlewares = middlewares;
    _currentIteration = Uuid().v4();
    final alreadyRegisteredMiddlewares = _configurations.values.map((e) => e.middlewares).expand((e) => e);
    for(final middleware in alreadyRegisteredMiddlewares) {
      if(_middlewares!.contains(middleware)) {
        throw ArgumentError('Middleware $middleware is already registered');
      }
    }
    return this;
  }

  MiddlewareConsumer forRoutes(List<RouteInfo> routes) {
    if(_middlewares == null) {
      throw ArgumentError('Use apply() before forRoutes()');
    }
    final flattedRoutes = _getFlatRoutes(routes);
    final forRoutes = _removeOverlappedRoutes(flattedRoutes);
    if(_configurations.containsKey(_currentIteration)) {
      _configurations[_currentIteration!] = _configurations[_currentIteration]!.copyWith(
        routes: forRoutes
      );
      return this;
    }
    final configuration = MiddlewareConfiguration(
      middlewares: _middlewares!,
      routes: forRoutes,
      controllers: [],
      excludedRoutes: []
    );
    _configurations[_currentIteration!] = configuration;
    return this;
  }

  MiddlewareConsumer forControllers(List<Type> controllers) {
    if(_middlewares == null) {
      throw ArgumentError('Use apply() before forControllers()');
    }
    if(_configurations.containsKey(_currentIteration)) {
      _configurations[_currentIteration!] = _configurations[_currentIteration]!.copyWith(
        controllers: controllers
      );
      return this;
    }
    final configuration = MiddlewareConfiguration(
      middlewares: _middlewares!,
      routes: [],
      controllers: controllers,
      excludedRoutes: []
    );
    _configurations[_currentIteration!] = configuration;
    return this;
  }

  MiddlewareConsumer exclude(List<RouteInfo> routes) {
    if(_middlewares == null) {
      throw ArgumentError('Use apply() before exclude()');
    }
    final excludeRoutes = <RouteInfo>[
      ...(_configurations[_currentIteration!]?.excludedRoutes ?? []),
      ..._getFlatRoutes(routes).fold<List<RouteInfo>>([], (acc, route) {
          for (final routePath in _pathExtractor.extractPathFrom(
            route,
          )) {
            acc.add(RouteInfo(
              path: routePath,
              method: route.method,
              versions: route.versions,
            ));
          }
          return acc;
      })
    ];
    _configurations[_currentIteration!] = _configurations[_currentIteration]!.copyWith(
      excludedRoutes: excludeRoutes,
    );
    return this;
  }

  List<RouteInfo> _getFlatRoutes(List<RouteInfo> routes) {
    return routes.expand((route) {
      if (route.versions != null) {
        return route.versions!.map((version) {
          return RouteInfo(
            path: route.path,
            method: route.method,
            versions: [version],
          );
        });
      }
      return [route];
    }).toList();
  }

  List<RouteInfo> _removeOverlappedRoutes(List<RouteInfo> routes) {
    final parametricRegex = RegExp(r'<[^>]+>');
    final wildcardRegex = '([^/]*)';
    final routesWithRegex = routes
      .where((route) => route.path.contains('<'))
      .map((route) {
        return (
          regex: RegExp(r'^(' '${route.path.replaceAll(parametricRegex, wildcardRegex)}' r')$'),
          route: route,
        );
      });
    return routes.where((route) {
      return routesWithRegex.isEmpty || routesWithRegex.any((item) {
        return !_isOverlapped(item, route);
      });
    }).toList();
  }

  bool _isOverlapped(({RegExp regex, RouteInfo route}) item, RouteInfo route) {
    if (route.method != item.route.method) {
      return false;
    }
    final normalizedRoutePath = item.route.path.stripEndSlash();
    return (
      normalizedRoutePath != item.route.path &&
      item.regex.hasMatch(normalizedRoutePath)
    );
  }

}