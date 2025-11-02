import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:mason/mason.dart';

final onRouteRegex = RegExp(r'on\(([^()]*|\([^()]*\))*\)');
final superParamsRegex = RegExp(r'super\(([^()]*|\([^()]*\))*\)', dotAll: true);
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
    final progress = logger.progress('Analyzing user defined routes');
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
        final resolvedUnit = await context.currentSession.getResolvedUnit(file)
            as ResolvedUnitResult;
        final declarations = resolvedUnit.unit.declarations;
        for (final declaration in declarations) {
          if (declaration is ClassDeclaration) {
            if (declaration.extendsClause?.superclass.toString() != 'Route') {
              continue;
            }
            final route = UserRoute(
              className: '${declaration.name.stringValue ?? declaration.name}',
            );
            for (final member in declaration.members) {
              if (member is ConstructorDeclaration) {
                if (member.redirectedConstructor != null ||
                    member.factoryKeyword != null) {
                  logger.warn(
                    'Skipping constructor ${member.name} for class ${declaration.name}',
                  );
                  continue;
                }
                for (final fragment in <FormalParameterFragment>[
                  ...member.declaredFragment?.formalParameters ?? <FormalParameterFragment>[],
                ]) {
                  final element = fragment.element;
                  if ((element.name == 'path' &&
                          element.isSuperFormal &&
                          route.path == null) ||
                      (element.name == 'path' && !element.isSuperFormal)) {
                    route
                      ..path = element.computeConstantValue()?.toStringValue()
                      ..parameters = buildParamDefinition(route.path ?? '')
                          .map((e) => e.name)
                          .toList();
                  }
                  if ((element.name == 'queryParameters' &&
                          element.isSuperFormal &&
                          route.queryParameters == null) ||
                      (element.name == 'queryParameters' &&
                          !element.isSuperFormal)) {
                    route.queryParameters = (element
                                .computeConstantValue()
                                ?.toMapValue()
                                ?.keys
                                .map((e) => e?.toStringValue() ?? '') ??
                            [])
                        .where((e) => e.isNotEmpty)
                        .toList();
                  }
                  if ((element.name == 'method' &&
                          element.isSuperFormal &&
                          route.method == null) ||
                      (element.name == 'method' && !element.isSuperFormal)) {
                    route.method =
                        element.toString().replaceAll('HttpMethod.', '');
                  }
                }
                final matches = superParamsRegex.allMatches(
                    member.toSource());
                for (final match in matches) {
                  final superCon = match.group(0);
                  if (superCon != null) {
                    final tokens = superCon
                        .replaceAll('super(', '')
                        .replaceAll(')', '')
                        .split(RegExp(r',\s*|,'));
                    for (final token in tokens) {
                      final trimmedToken = token.trim();
                      if (trimmedToken.startsWith('path:')) {
                        final path = trimmedToken
                            .split('path:')
                            .last
                            .replaceAll("'", '')
                            .trim();
                        route.path = path;
                      }
                      if (token.startsWith('method:')) {
                        final method = token.split('method:').last.trim();
                        route.method = method.replaceAll('HttpMethod.', '');
                      }
                      if (token.startsWith('queryParameters:')) {
                        final queryString = RegExp(
                          r'queryParameters:\s*{.*}',
                          dotAll: true,
                        ).allMatches(token);
                        for (final queryToken in queryString) {
                          var firstResult = queryToken.group(0);
                          if (firstResult != null) {
                            firstResult = firstResult
                                .replaceAll('\n', '')
                                .replaceAll(
                                    RegExp(
                                      r'queryParameters:\s*{',
                                      dotAll: true,
                                    ),
                                    '')
                                .replaceAll('}', '');
                            final parameters =
                                RegExp('\'.*\'|".*"').allMatches(firstResult);
                            route.queryParameters = parameters
                                .map(
                                  (e) => e.group(0)?.replaceAll("'", '') ?? '',
                                )
                                .where((e) => e.isNotEmpty)
                                .toList();
                          }
                        }
                        // final queryMap = jsonDecode(queryString);
                      }
                    }
                  }
                }
              }
            }
            userDefinedRoutes[route.className] = route;
          }
        }
      }
    }
    progress.complete('User-defined routes analysis completed!');
    logger.info('🎯 Found ${userDefinedRoutes.length} user-defined routes!');
    return userDefinedRoutes;
  }

  Future<Map<String, Controller>> analyzeControllers(
    List<File> files,
    Map<String, UserRoute> routes,
    Map<String, dynamic> config,
    Logger logger,
  ) async {
    final analysisProgress =
        logger.progress('Analyzing application controllers');
    final collection = AnalysisContextCollection(
      includedPaths: files.map((file) => file.path).toList(),
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    final result = <String, Controller>{};
    for (final file in files) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      final context = collection.contextFor(file.path);
      final resolvedUnit = (await context.currentSession
          .getResolvedUnit(file.path)) as ResolvedUnitResult;
      for (final declaration in resolvedUnit.unit.declarations) {
        if (declaration is ClassDeclaration) {
          if (declaration.extendsClause?.superclass.toString() !=
              'Controller') {
            continue;
          }
          String? controllerPath;
          final controllerRoutes = <Route>[];
          final classMethods = List<MethodDeclaration>.from(
              declaration.members.whereType<MethodDeclaration>());
          for (final member in declaration.members) {
            if (member is ConstructorDeclaration) {
              if (member.redirectedConstructor != null ||
                  member.factoryKeyword != null) {
                logger.warn(
                  'Skipping constructor ${member.name} for class ${declaration.name}',
                );
                continue;
              }
              member.declaredFragment?.formalParameters.forEach((parameter) {
                if (parameter.name == 'path' && parameter.element.isSuperFormal) {
                  controllerPath =
                      parameter.element.computeConstantValue()?.toStringValue();
                }
              });
              controllerRoutes.addAll(
                  _getOnMethodsArguments(logger, member, routes, classMethods));
            }
          }
          final className = declaration.name.stringValue ?? declaration.name;
          if (controllerPath == null) {
            final params = superParamsRegex.allMatches(declaration.toSource());
            final superCons = params.first.group(0);
            final ps = superCons
                ?.replaceAll('super(', '')
                .replaceAll(')', '')
                .split('path:')
                .lastOrNull
                ?.trim()
                .replaceAll("'", '');
            if (ps == null) {
              logger.warn(
                  'The controller ($className) path is null or cannot be parsed! Skipping.');
              continue;
            }
            controllerPath = ps;
          }
          result['$className'] = Controller(
            controllerPath!,
            controllerRoutes,
          );
        }
      }
    }
    analysisProgress.complete('Application analysis completed!');
    logger.info(
        '✨ Found ${result.values.expand((e) => e.routes).length} routes in your application!');
    return result;
  }

  List<Route> _getOnMethodsArguments(
      Logger logger,
      ConstructorDeclaration constructor,
      Map<String, UserRoute> userRoutes,
      List<MethodDeclaration> methods) {
    final routes = <Route>[];
    for (final child in constructor.childEntities) {
      if (child is BlockFunctionBody) {
        for (final entity in child.block.childEntities) {
          if (entity is ExpressionStatement) {
            if (entity.expression is MethodInvocation) {
              var route = Route();
              final methodInvocation = entity.expression as MethodInvocation;
              for (final arg in methodInvocation.argumentList.arguments) {
                if (arg is InstanceCreationExpression &&
                    userRoutes
                        .containsKey(arg.staticType?.getDisplayString())) {
                  if (arg.argumentList.arguments.isEmpty) {
                    route = Route.fromUserRoute(
                        userRoutes[arg.staticType?.getDisplayString()]!);
                  }
                }
                if (arg is InstanceCreationExpression &&
                    arg.staticType?.getDisplayString() == 'Route' &&
                    arg.constructorName.name != null) {
                  route.method =
                      arg.constructorName.name.toString().toLowerCase();
                  for (final instanceArg in arg.argumentList.arguments) {
                    if (instanceArg is SingleStringLiteral) {
                      var routePath = instanceArg.stringValue;
                      final parameters = buildParamDefinition(routePath ?? '')
                          .map((e) => e.name)
                          .toList();
                      for (final param in parameters) {
                        routePath = routePath?.replaceFirst(
                          '<$param>',
                          '\$$param',
                        );
                      }
                      route
                        ..parameters = parameters
                        ..path = routePath
                        ..rawPath = instanceArg.stringValue;
                    }
                  }
                }
                if (arg is FunctionExpression) {
                  route.returnType = arg.declaredFragment?.element.returnType;
                }
                if (arg is NamedExpression) {
                  if (arg.name.label.name == 'body') {
                    route.bodyType = arg.expression.toString();
                  }
                }
                if (arg is SimpleIdentifier) {
                  final m = methods
                      .where((e) =>
                          (e.name.stringValue ?? e.name.toString()) ==
                          (arg.token.stringValue ?? arg.token.toString()))
                      .firstOrNull;
                  if (m != null) {
                    route.returnType = m.returnType?.type;
                  }
                }
              }
              if (route.path != null) {
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
        part,
        null,
        'Parameter definition is invalid. Close door neighbors',
      );
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

  String getBasePath(ClassElement clazz) {
    final pathField = clazz.getField('path');
    if (pathField != null) {
      return pathField.computeConstantValue()?.toStringValue() ?? '/';
    }
    return clazz.unnamedConstructor?.formalParameters
            .where((p) => p.name == 'path')
            .first
            .computeConstantValue()
            ?.toStringValue() ??
        '/';
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
  const Controller(this.path, this.routes);

  final String path;

  final List<Route> routes;
}

class Route {
  factory Route.fromUserRoute(UserRoute userRoute) {
    var routePath = userRoute.path;
    for (final param in userRoute.parameters ?? []) {
      routePath = routePath?.replaceFirst(
        '<$param>',
        '\$$param',
      );
    }
    return Route()
      ..rawPath = userRoute.path
      ..method = userRoute.method
      ..parameters = userRoute.parameters ?? []
      ..path = routePath
      ..queryParamters = {
        for (var e in userRoute.queryParameters ?? []) e.toString(): e.hashCode
      };
  }

  Route();

  String? rawPath;
  String? path;
  String? method;
  DartType? returnType;
  String? bodyType;
  Map<String, dynamic> queryParamters = {};
  List<String> parameters = [];
}
