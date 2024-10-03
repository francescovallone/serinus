import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:code_builder/code_builder.dart';
import 'package:mason/mason.dart';

const ON_ROUTE_REGEX = r'on\(([^()]*|\([^()]*\))*\)';
const SUPER_PARAMS_REGEX = r'super\(([^()]*|\([^()]*\))*\)';

class ControllersAnalyzer {

  Future<Map<String, dynamic>> analyzeRoutes(
    List<File> files,
    Map<String, dynamic> config,
    Logger _logger,
  ) async {
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

          
        }
      }
    }
    return {};
  }

  Future<dynamic> analyzeControllers(
    List<File> files, 
    Map<String, dynamic> routes,
    Map<String, dynamic> config,
    Logger _logger,
  ) async {
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
          print(name);
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
          final matches = RegExp(ON_ROUTE_REGEX).allMatches(clazz.source.contents.data);
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
                  _logger.err(
                    'Invalid route definition: $result in controller $name',);
                }
              }
            }
          }
          
        }
      }
    }
  }

  UserRoute getRouteInformation(ClassElement clazz) {
    final constructor = clazz.unnamedConstructor;
    final content = constructor?.source.contents.data;
    final userRoute = UserRoute();
    final results = RegExp(SUPER_PARAMS_REGEX).allMatches(content ?? '');
    for(final result in results) {
      for (var i = 0; i<result.groupCount; i++) {
        var superParams = result.group(i);
        if(superParams != null) {
          superParams = superParams.substring(6, superParams.length - 1).trim();
          final params = superParams.split(',');
          for(final param in params) {
            final tokens = param.split(':');
            if(tokens.length == 2) {
              final key = tokens[0].trim();
              final value = tokens[1].trim();
              if(key == 'path') {
                userRoute.path = value;
              }
              if(key == 'method') {
                userRoute.method = value;
              }
              if(key == 'queryParamters') {
                userRoute.queryParamters = {};
                final queryParamters = value.substring(1, value.length - 1).split(',');
                for(final queryParam in queryParamters) {
                  final queryTokens = queryParam.split(':');
                  if(queryTokens.length == 2) {
                    final queryKey = queryTokens[0].trim();
                    final queryValue = queryTokens[1].trim();
                    userRoute.queryParamters![queryKey] = queryValue;
                  }
                }
              }
            }
          }
        }
      }
    }
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
    print(userRoute);
              print(constructor?.parameters);
          print(constructor?.source.contents.data);
          print(constructor?.superConstructor?.parameters.map((p) => p.computeConstantValue()));
          print(clazz.constructors);
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

  final String name;
  final List<Route> routes;

  const ControllerEntry({
    required this.name,
    required this.routes,
  });

}

class UserRoute {

  String? path;
  String? method;
  Map<String, dynamic>? queryParamters;
  Map<String, dynamic>? parameters;

  UserRoute({
    this.path,
    this.method,
    this.queryParamters,
    this.parameters
  });

  @override
  String toString() {
    return 'UserRoute(path: $path, method: $method, queryParamters: $queryParamters, parameters: $parameters)';
  }

}

class Route {

  final String name;
  final String method;
  final Map<String, dynamic> queryParamters;
  final Map<String, dynamic> parameters;

  const Route({
    required this.name,
    required this.method,
    this.queryParamters = const {},
    this.parameters = const {}
  });

}
