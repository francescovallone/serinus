import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:mason/mason.dart';

const ON_ROUTE_REGEX = r'on\(([^()]*|\([^()]*\))*\)';

class ControllersAnalyzer {

  Future<dynamic> analyze(
    List<File> files, 
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
          print(getBasePath(clazz));
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

class Route {

  final String name;
  final String method;

  const Route({
    required this.name,
    required this.method,
  });

}
