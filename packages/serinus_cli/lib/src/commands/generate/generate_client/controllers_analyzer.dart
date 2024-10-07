import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:mason/mason.dart';
import 'package:serinus_cli/src/utils/extensions.dart';

final onRouteRegex = RegExp(r'on\(([^()]*|\([^()]*\))*\)');
final superParamsRegex = RegExp(r'super\(([^()]*|\([^()]*\))*\)');
final parametricDefnsRegex = RegExp(r'([^<]*)<(\w+)>([^<]*)');
final closeDoorParametricRegex = RegExp('><');

typedef ParamRecord = ({
  String name,
  String? prefix,
  String? suffix,
});

class ControllersAnalyzer {

  Future<Map<String, UserRoute>> analyzeRoutes(
    List<File> files,
    Map<String, dynamic> config,
    Logger logger,
  ) async {
    logger.info('Analyzing user defined routes');
    final userDefinedRoutes = <String, UserRoute>{};
    final collection = AnalysisContextCollection(
      includedPaths: files.map((file) => file.path).toList(),
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    for (final context in collection.contexts) {
      for (final file in context.contextRoot.analyzedFiles()) {
        if (!file.endsWith('.dart')) {
          continue;
        }
        final unitElement = await context.currentSession.getUnitElement(file);
        final unit = unitElement as UnitElementResult;
        final element = unit.element;
        final classes = element.classes;
        for (final clazz in classes) {
          final name = clazz.name;
          final isRoute = clazz.allSupertypes.where(
            (t) => t.getDisplayString().contains('Route'),).isNotEmpty;
          if (!isRoute) {
            continue;
          }
          final constructor = clazz.unnamedConstructor;
          if(!(constructor?.isDefaultConstructor ?? false)) {
            _logger.err('Route $name must have a default constructor');
            continue;
          }
          final userRoute = getRouteInformation(clazz);
          userDefinedRoutes[userRoute.className] = userRoute;
        }
      }
    }
    return userDefinedRoutes;
  }

  Future<dynamic> analyzeControllers(
    List<File> files, 
    Map<String, dynamic> routes,
    Map<String, dynamic> config,
    Logger logger,
  ) async {
    logger.info('Analyzing application controllers');
    final collection = AnalysisContextCollection(
      includedPaths: files.map((file) => file.path).toList(),
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    for (final context in collection.contexts) {
      final superController = await context.currentSession.getLibraryByUri('package:serinus/src/core/controller.dart');
      final controllerElement = (superController as LibraryElementResult).element;
      for (final file in context.contextRoot.analyzedFiles()) {
        if (!file.endsWith('.dart')) {
          continue;
        }
        final unitElement = await context.currentSession.getUnitElement(file);
        final unit = unitElement as UnitElementResult;
        final element = unit.element;
        final classes = element.classes;
        for (final clazz in classes) {
          final name = clazz.name;
          final isController = clazz.allSupertypes.where(
            (t) => t.getDisplayString().contains('Controller'),).isNotEmpty;
          if (!isController) {
            continue;
          }
          final constructor = clazz.unnamedConstructor;
          if(!(constructor?.isDefaultConstructor ?? false)) {
            _logger.err('Controller $name must have a default constructor');
            continue;
          }
          final basePath = getBasePath(clazz);
          // print(basePath);
          final routes = <Route>[];
          final matches = onRouteRegex.allMatches(clazz.source.contents.data);
          for(final match in matches) {
            for (var i = 0; i<match.groupCount; i++) {
              var result = match.group(i);
              if(result != null) {
                result = result.substring(3, result.length - 1).trim();
                final routeTokens = result.split(',');
                if(routeTokens.length != 2) {
                  _logger.err(
                    'Invalid route definition: $result in controller $name',);
                  continue;
                }
                final route = routeTokens[0].trim();
                if(route.contains('Route.')){
                  final routeName = route.split('.')[1];
                  final method = routeTokens[1].trim();                  
                  routes.add(Route(name: routeName, method: method));
                } else {
                  final routeName = route.split('(')[1];
                  final method = routeTokens[1].trim();
                  final queryParameters = <String, dynamic>{};
                  final parameters = <String, dynamic>{};
                  final queryParametersMatches = superParamsRegex.allMatches(result);
                  for(final queryParametersMatch in queryParametersMatches) {
                    for (var i = 0; i < queryParametersMatch.groupCount; i++) {
                      var superParams = queryParametersMatch.group(i);
                      if(superParams != null) {
                        superParams = superParams.substring(6, superParams.length - 1).trim();
                        final params = superParams.split(',');
                        for(final param in params) {
                          final tokens = param.split(':');
                          if(tokens.length >= 2) {
                            final key = tokens[0].trim();
                            final value = tokens[1].trim();
                            queryParameters[key] = value;
                          }
                        }
                      }
                    }
                  }
                  final params = buildParamDefinition(route);
                  for(final param in params) {
                    route = route.replaceFirst(
                      '<${param.name}>', '\${params["${param.name}"]}',);
                  }
                  parameters['path'] = route;
                  parameters['method'] = method;
                  parameters['queryParameters'] = queryParameters;
                  routes.add(Route(name: routeName, method: method, queryParamters: queryParameters, parameters: parameters));
                }
              }
            }
          }
          
        }
      }
    }
  }

  ParamRecord _singleParamDefn(RegExpMatch m) {
    var suffix = m.group(3)?.nullIfEmpty;
    if(suffix != null && (suffix.endsWith("'"))) {
      suffix = suffix.substring(0, suffix.length - 1);
    }
    var prefix = m.group(1)?.nullIfEmpty;
    if(prefix != null && (prefix.startsWith("'"))) {
      prefix = prefix.substring(1);
    }
    return (
      name: m.group(2)!,
      prefix: prefix,
      suffix: suffix,
    );
  }

  List<ParamRecord> buildParamDefinition(String part) {
    if (closeDoorParametricRegex.hasMatch(part)) {
      throw ArgumentError.value(
          part, null, 'Parameter definition is invalid. Close door neighbors',);
    }

    final matches = parametricDefnsRegex.allMatches(part);
    if (matches.isEmpty) {
      return [];
    }

    if (matches.length == 1) {
      return [_singleParamDefn(matches.first)];
    }

    return matches.map(_singleParamDefn).toList();
  }

  UserRoute getRouteInformation(ClassElement clazz) {
    final constructor = clazz.unnamedConstructor;
    final content = constructor?.source.contents.data;
    final userRoute = UserRoute(
      className: clazz.name,
    );
    final pathGetter = clazz.getField('path');
    var path = pathGetter?.computeConstantValue()?.toStringValue() ?? clazz.getField('path')?.computeConstantValue()?.toStringValue();
    if(path == null && (constructor?.parameters.isNotEmpty ?? false)){
      final pathParameter = constructor?.parameters.where(
        (p) => p.name == 'path' || p.name == 'super.path').firstOrNull;
      path = pathParameter?.computeConstantValue()?.toStringValue();
    }
    userRoute.path = userRoute.path ?? path;
    final methodGetter = clazz.getField('method');
    var method = methodGetter?.computeConstantValue()?.toStringValue() ?? clazz.getField('method')?.computeConstantValue()?.toStringValue();
    if(method == null && (constructor?.parameters.isNotEmpty ?? false)){
      final methodParameter = constructor?.parameters.where(
        (p) => p.name == 'method' || p.name == 'super.method').firstOrNull;
      method = methodParameter?.computeConstantValue()?.toStringValue();
    }
    userRoute.method = userRoute.method ?? method;
    final queryParametersGetter = clazz.getField('queryParameters');
    var queryParameters = queryParametersGetter?.computeConstantValue()?.toMapValue();
    if(queryParameters == null && (constructor?.parameters.isNotEmpty ?? false)){
      final queryParametersParameter = constructor?.parameters.where(
        (p) => p.name == 'queryParameters' || p.name == 'super.queryParameters',
      ).firstOrNull;
      queryParameters = queryParametersParameter?.computeConstantValue()?.toMapValue();
    }
    userRoute.queryParameters = userRoute.queryParameters ?? 
      queryParameters?.keys.map((k) => k.toString()).toList() ?? [];
    final results = superParamsRegex.allMatches(content ?? '');
    for(final result in results) {
      for (var i = 0; i < result.groupCount; i++) {
        var superParams = result.group(i);
        if(superParams != null) {
          superParams = superParams.substring(6, superParams.length - 1).trim();
          final params = superParams.split(',');
          var index = 0;
          for(final param in params.indexed) {
            final tokens = param.$2.split(':');
            if(tokens.length >= 2) {
              final key = tokens[0].trim();
              final value = tokens[1].trim();
              if(key == 'path') {
                userRoute.path = value;
              }
              if(key == 'method') {
                userRoute.method = value.replaceAll('HttpMethod.', '');
              }
              if(key == 'queryParameters') {
                index = param.$1;
              }

            }
          }
          var query = params.sublist(index).map((e) => e.trim()).join().trim();
          final closingParenthesis = query.indexOf('}');
          query = query.replaceRange(closingParenthesis + 1, query.length, '')
            .replaceAll('queryParameters:', '')
            .replaceAll(' ', '').replaceAll('\n', '')
            .replaceAll("'", '"').trim();
          if(query.isNotEmpty) {
            query = query.substring(1, query.length - 1);
            final tokens = query.split(',');
            if(tokens.isNotEmpty) {
              userRoute.queryParameters = [];
            }
            for(final token in tokens) {
              final key = token.split(':')[0].trim();
              userRoute.queryParameters?.add(key);
            }
          }
        }
      }
    }
    final params = buildParamDefinition(userRoute.path ?? '');
    for(final param in params) {
      userRoute.path = userRoute.path?.replaceFirst(
        '<${param.name}>', '\${params["${param.name}"]}',);
    }
    userRoute.parameters = params.map((p) => p.name).toList();
    return userRoute;
  }

  String getBasePath(ClassElement clazz) {
    final pathField = clazz.getField('path');
    if(pathField != null) {
      return pathField.computeConstantValue()?.toStringValue() ?? '/';
    }
    return clazz.unnamedConstructor?.parameters.where((p) => p.name == 'path').first.computeConstantValue()?.toStringValue() ?? '/';
  }

}


class ControllerEntry {

  const ControllerEntry({
    required this.name,
    required this.routes,
  });

  final String name;
  final List<Route> routes;

}

class UserRoute {

  UserRoute({
    required this.className,
    this.path,
    this.method,
    this.queryParameters,
    this.parameters,
  });

  final String className;
  String? path;
  String? method;
  List<String>? queryParameters;
  List<String>? parameters;

  @override
  String toString() {
    return 'UserRoute(name: $className, path: $path, method: $method, queryParameters: $queryParameters, parameters: $parameters)';
  }

}

class Route {

  const Route({
    required this.name,
    required this.method,
    this.queryParamters = const {},
    this.parameters = const {}
  });

  final String name;
  final String method;
  final Map<String, dynamic> queryParamters;
  final Map<String, dynamic> parameters;

}
