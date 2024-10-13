import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:mason/mason.dart';

final onRouteRegex = RegExp(r'on\(([^()]*|\([^()]*\))*\)');
final superParamsRegex = RegExp(r'super\(([^()]*|\([^()]*\))*\)');
final parametricDefnsRegex = RegExp(r'<(\w+)>');
final closeDoorParametricRegex = RegExp('><');

typedef ParamRecord = ({
  String name,
  String? prefix,
  String? suffix,
});

class ControllerAstVisitor extends GeneralizingAstVisitor<Object> {

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    super.visitFunctionDeclarationStatement(node);
  }

}

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
            logger.err('Route $name must have a default constructor');
            continue;
          }
          final userRoute = getRouteInformation(clazz);
          userDefinedRoutes[userRoute.className] = userRoute;
        }
      }
    }
    return userDefinedRoutes;
  }

  Future<Map<String, Controller>> analyzeControllers(
    List<File> files, 
    Map<String, dynamic> routes,
    Map<String, dynamic> config,
    Logger logger,
  ) async {
    final analysisProgress = logger.progress('Analyzing application controllers');
    final collection = AnalysisContextCollection(
      includedPaths: files.map((file) => file.path).toList(),
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    final result = <String, Controller>{};
    for (final file in files) {
      if(!file.path.endsWith('.dart')) {
        continue;
      }
      final context = collection.contextFor(file.path);
      final resolvedUnit = (await context.currentSession.getResolvedUnit(file.path)) as ResolvedUnitResult;
      for(final declaration in resolvedUnit.unit.declarations) {
        if(declaration is ClassDeclaration) {
          if (
            declaration.extendsClause?.superclass.toString() != 'Controller') {
            continue;
          }
          String? controllerPath;
          final controllerRoutes = <Route>[];
          for(final member in declaration.members) {
            if (member is ConstructorDeclaration) {
              if(
                member.redirectedConstructor != null || 
                member.factoryKeyword != null
              ) {
                logger.warn(
                  'Skipping constructor ${member.name} for class ${declaration.name}',
                );
                continue;
              }
              member.declaredElement?.parameters.forEach((element) {
                if(element.name == 'path' && element.isSuperFormal) {
                  controllerPath = element.computeConstantValue()
                    ?.toStringValue();
                }
              });
              controllerRoutes.addAll(_getOnMethodsArguments(member));
            }
          }
          final className = declaration.name.stringValue ?? declaration.name;
          if(controllerPath == null) {
            logger.warn('The controller ($className) path is null or cannot be parsed! Skipping.');
            continue;
          }
          result['$className'] = Controller(
            controllerPath!,
            controllerRoutes,
          );
        }
      }
    }
    analysisProgress.complete('Analysis completed!');
    return result;
  }

  List<Route> _getOnMethodsArguments(ConstructorDeclaration constructor) {
    final routes = <Route>[];
    for(final child in constructor.childEntities) {
      if(child is BlockFunctionBody) {
        for(final entity in child.block.childEntities) {
          if(entity is ExpressionStatement) {
            if(entity.expression is MethodInvocation) {      
              final route = Route();
              final methodInvocation = entity.expression as MethodInvocation;
              for (final arg in methodInvocation.argumentList.arguments) {
                if(
                  arg is InstanceCreationExpression && 
                  arg.staticType?.getDisplayString() == 'Route' &&
                  arg.constructorName.name != null
                ) {
                  route.method = arg.constructorName.name.toString()
                    .toLowerCase();
                  for(final instanceArg in arg.argumentList.arguments) {
                    if(instanceArg is SingleStringLiteral) {
                      var routePath = instanceArg.stringValue;
                      final parameters = buildParamDefinition(routePath ?? '')
                        .map((e) => e.name).toList();
                      print(parameters);
                      for(final param in parameters) {
                        routePath = routePath?.replaceFirst(
                          '<$param>', '\$$param',);
                      }
                      route..parameters = parameters
                        ..path = routePath
                      ..rawPath = instanceArg.stringValue;
                    }  
                  }
                }
                if(arg is FunctionExpression) {
                  route.returnType = arg.declaredElement
                    ?.returnType.getDisplayString();
                }
                if(arg is NamedExpression) {
                  if(arg.name.label.name == 'body') {
                    route.bodyType = arg.expression.toString();
                  }
                }
              }
              if(route.path != null) {
                routes.add(route);
              }
            }
          }
        }
      }

    }
    return routes;
  }

  ParamRecord _singleParamDefn(RegExpMatch m) {
    return (
      name: m.group(0)!.replaceAll('<', '').replaceAll('>', ''),
      prefix: null,
      suffix: null,
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

class Controller {

  final String path;

  final List<Route> routes;

  const Controller(this.path, this.routes);

}

class Route {

  Route();

  String? rawPath;
  String? path;
  String? method;
  String? returnType;
  String? bodyType;
  Map<String, dynamic> queryParamters = {};
  List<String> parameters = [];

}
