import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:openapi_types/openapi_types.dart';

class Analyzer {

  final OpenApiVersion version;

  Analyzer(this.version);

  Map<String, List<RouteDescription>> analyze() {
    FileSystemEntity file = Directory.current;
    final collection = AnalysisContextCollection(includedPaths: [file.absolute.path]);
    final handlersByControllers = <String, List<RouteDescription>>{};
    for (final context in collection.contexts) {
      final analyzedFiles = context.contextRoot.analyzedFiles();
      for(final filePath in analyzedFiles) {
        if (!filePath.endsWith('.dart') || !filePath.contains('bin')) {
          continue;
        }
        final SomeParsedLibraryResult result = context.currentSession.getParsedLibrary(filePath);
        if (result is ParsedLibraryResult) {
          for (final unit in result.units) {
            for (final declaration in unit.unit.declarations) {
              final methods = <MethodDeclaration>[];
              final constructors = <ConstructorDeclaration>[];
              final handlers = <String, RouteDescription>{};
              bool isController = false;
              String controllerName = '';
              for (final child in declaration.childEntities) {
                if (child is ExtendsClause) {
                  if (child.superclass.name2.value() != 'Controller') {
                    break;
                  } else {
                    isController = true;
                  }
                }
                if (child is Token && child.type == TokenType.IDENTIFIER) {
                  controllerName = child.value().toString();
                }
                if (child is MethodDeclaration) {
                  methods.add(child);
                } else if (child is ConstructorDeclaration) {
                  constructors.add(child);
                  final blockFunctionBody = child.childEntities.whereType<BlockFunctionBody>().firstOrNull;
                  if (blockFunctionBody != null) {
                    final block = blockFunctionBody.block;
                    final statements = block.statements.whereType<ExpressionStatement>();
                    final analyzedHandlers = _analyzeStatements(statements);
                    handlers.addAll(analyzedHandlers);
                  }
                }
              }
              // for (final method in methods) {
              //   final savedHandler = handlers[method.name.value()];
              //   if (savedHandler != null) {
              //     final returnType = method.returnType?.toSource();
              //     if (returnType != null) {
              //       savedHandler.returnType = _parseMethodDeclarationToOpenApiResponse(method);
              //     }
              //   }
              // }
              if (isController) {
                handlersByControllers[controllerName] = handlers.values.toList();
              }
            }
          }
        }
      }
    }
    return handlersByControllers;
  }

  RouteResponse _parseMethodDeclarationToOpenApiResponse(MethodDeclaration method) {
    final returnType = method.returnType?.toSource();
    if (returnType != null) {
      if (returnType.startsWith('Future<')) {
        final innerType = returnType.substring(7, returnType.length - 1);
        return RouteResponse(responseType: _convertTypeToOpenApiType(innerType));
      } else if (returnType == 'void') {
        return RouteResponse(responseType: OpenApiType.object());
      } else if (returnType.startsWith('Stream<')) {
        final innerType = returnType.substring(7, returnType.length - 1);
        return RouteResponse(
          responseType: OpenApiType.array(), properties: {
            'application/json': JsonSchema(
              type: _convertTypeToOpenApiType(innerType),
            ),
          }
        );
      } else if (returnType.startsWith('FutureOr<')) {
        final innerType = returnType.substring(10, returnType.length - 1);
        return RouteResponse(responseType: _convertTypeToOpenApiType(innerType));
      } else {
        return RouteResponse(responseType: OpenApiType.object(), properties: {
          'application/json': JsonSchema(
            type: _convertTypeToOpenApiType(returnType),
          ),
        });
      }
    }
    return RouteResponse(responseType: OpenApiType.object());
  }
  
  Map<String, RouteDescription> _analyzeStatements(Iterable<ExpressionStatement> statements) {
    final handlers = <String, RouteDescription>{};
    for (final statement in statements) {
      if(statement.beginToken.value().toString() == 'ON') {
        final methods = statement.childEntities.whereType<MethodInvocation>();
        final analyzedMethods = _analyzeMethods(methods);
        handlers.addAll(analyzedMethods);
      }
    }
    return handlers;
  }

  Map<String, RouteDescription> _analyzeMethods(Iterable<MethodInvocation> methods) {
    final handlers = <String, RouteDescription>{};
    for (final method in methods) {
      final arguments = method.argumentList.arguments;
      if (arguments.isNotEmpty) {
        handlers.addAll(_analyzeArguments(arguments));
      }
    }
    return handlers;
  }

  Map<String, RouteDescription> _analyzeArguments(Iterable<Expression> expressions) {
    final handlers = <String, RouteDescription>{};
    for (final expr in expressions) {
      if (expr is SimpleIdentifier) {
        handlers[expr.name] = RouteDescription();
      } else if (expr is FunctionExpression) {
        final body = expr.body;
        if (body is ExpressionFunctionBody) {
          final bodyExpr = body.expression;
          handlers[expr.toSource()] = _analyzeReturnType(bodyExpr);
          continue;
        }
        if(body is BlockFunctionBody) {
          for (final statement in body.block.statements) {
            if(statement is ReturnStatement) {
              final returnExpr = statement.expression;
              if (returnExpr != null) {
                handlers[expr.toSource()] = _analyzeReturnType(returnExpr);
              } else {
                handlers[expr.toSource()] = RouteDescription();
              }
            }
          }
        }
      }
    }
    return handlers;
  }

  RouteDescription _analyzeReturnType(Expression expr) {
    final description = RouteDescription();
    if(expr is SetOrMapLiteral) {
      description.returnType = version == OpenApiVersion.v2 ?
        ResponseObjectV2(
          description: 'Success response',
          schema: _describeValueInOpenApiFormat(_analyzeSetOrMapLiteral(expr)),
        ) :
        ResponseObjectV3(
          description: 'Success response',
          content: {
            _analyzeValueToContentType(expr): MediaTypeObjectV3(
              schema: _describeValueInOpenApiFormat(_analyzeSetOrMapLiteral(expr)),
            )
          }
        );
    }
    return description;
  }

  Map<dynamic, dynamic> _analyzeSetOrMapLiteral(SetOrMapLiteral map) {
    final mapEntries = <dynamic, dynamic>{};
    for (final element in map.elements) {
      if (element is MapLiteralEntry) {
        final key = element.key;
        final value = element.value;
        if (key is SimpleStringLiteral) {
          mapEntries[key.value] = _analyzeExpression(value);
        } else if (key is IntegerLiteral) {
          mapEntries[key.value] = _analyzeExpression(value);
        } else if (key is BooleanLiteral) {
          mapEntries[key.value] = _analyzeExpression(value);
        }
      }
    }
    return mapEntries;
  }
  
  dynamic _analyzeExpression(Expression expr) {
    if (expr is SimpleStringLiteral) {
      return 'string';
    } else if (expr is IntegerLiteral) {
      return 'int';
    } else if (expr is DoubleLiteral) {
      return 'double';
    } else if (expr is StringLiteral) {
      return 'string';
    } else if (expr is StringInterpolation) {
      return 'string';
    } else if (expr is BooleanLiteral) {
      return 'bool';
    } else if (expr is SetOrMapLiteral) {
      return _analyzeSetOrMapLiteral(expr);
    } else if (expr is ListLiteral) {
      return _analyzeListLiteral(expr);
    } else if (expr is NullLiteral) {
      return null;
    }
    return expr.toSource();
  }

  List<dynamic> _analyzeListLiteral(ListLiteral list) {
    final listEntries = <dynamic>[];
    for (final element in list.elements) {
      listEntries.add(_analyzeCollectionElement(element));
    }
    return listEntries;
  }

  dynamic _analyzeCollectionElement(CollectionElement element) {    
    return null;
  }

  Map<String, OpenApiObject> _describeObjectInOpenApiFormat(Map<dynamic, dynamic> map) {
    final properties = <String, OpenApiObject>{};
    for (final entry in map.entries) {
      properties[entry.key.toString()] = _prepareJsonSchema(entry.value);
    }
    return properties;
  }

  JsonSchema _prepareJsonSchema(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'string':
          return JsonSchema(
            type: OpenApiType.string(),
          );
        case 'int':
          return JsonSchema(
            type: OpenApiType.int32(),
          );
        case 'double':
          return JsonSchema(
            type: OpenApiType.double(),
          );
        case 'bool':
          return JsonSchema(
            type: OpenApiType.boolean(),
          );
        default:
          return JsonSchema(
            type: OpenApiType.string(),
          );
      }
    } else if (value is int) {
      return JsonSchema(
        type: OpenApiType.int32(),
      );
    } else if (value is double) {
      return JsonSchema(
        type: OpenApiType.double(),
      );
    } else if (value is bool) {
      return JsonSchema(
        type: OpenApiType.boolean(),
      );
    } else if (value is Map) {
      return JsonSchema(
        type: OpenApiType.object(),
        properties: _describeObjectInOpenApiFormat(value),
      );
    } else if (value is List) {
      if (value.isEmpty) {
        return JsonSchema(
          type: OpenApiType.array(),
          items: JsonSchema(
            type: OpenApiType.object(),
            properties: {
              _analyzeValueToContentType(value) : JsonSchema(
                type: OpenApiType.object(),
              )
            }
          ),
        );
      }
    }
    return JsonSchema(
      type: OpenApiType.object(),
    );
  }

  String _analyzeValueToContentType(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'string':
          return 'text/plain';
        case 'int':
        case 'double':
        case 'bool':
          return 'application/json';
        default:
          return 'application/json';
      }
    } else if (value is int || value is double || value is bool) {
      return 'application/json';
    } else if (value is Map || value is List) {
      return 'application/json';
    }
    return 'application/json';
  }

  OpenApiObject _describeValueInOpenApiFormat(dynamic value) {
    if (value is String) {
      return _prepareJsonSchema(value);
    } else if (value is int) {
      return _prepareJsonSchema(value);
    } else if (value is double) {
      return _prepareJsonSchema(value);
    } else if (value is bool) {
      return _prepareJsonSchema(value);
    } else if (value is Map) {
      return _prepareJsonSchema(value);
    } else if (value is List) {
      if (value.isEmpty) {
        return JsonSchema(
          type: OpenApiType.array(),
          items: JsonSchema(
            type: OpenApiType.object(),
            properties: {
              'application/json': JsonSchema(
                type: OpenApiType.object(),
              )
            }
          ),
        );
      } else {
        final first = value.first;
        return JsonSchema(
          type: OpenApiType.array(),
          items: JsonSchema(
            type: _prepareJsonSchema(first).type,
            properties: {
              _analyzeValueToContentType(first): _prepareJsonSchema(first),
            }
          ),
        );
      }
    }
    return JsonSchema(
      type: OpenApiType.object(),
    );
  }

  OpenApiType _convertTypeToOpenApiType(String type) {
    switch (type.replaceAll('?', '')) {
      case 'int':
      case 'Int':
      case 'Integer':
      case 'int32':
        return OpenApiType.int32();
      case 'int64':
      case 'Int64':
      case 'long':
        return OpenApiType.int64();
      case 'double':
      case 'Double':
        return OpenApiType.double();
      case 'float':
      case 'Float':
        return OpenApiType.float();
      case 'String':
      case 'string':
        return OpenApiType.string();
      case 'bool':
      case 'Bool':
      case 'boolean':
        return OpenApiType.boolean();
      case 'DateTime':
        return OpenApiType.dateTime();
      case 'Date':
        return OpenApiType.date();
      case 'List':
      case 'list':
      case 'Array':
      case 'array':
        return OpenApiType.array();
      case 'Map':
      case 'map':
      case 'Object':
      case 'object':
        return OpenApiType.object();
      default:
        return OpenApiType.object();
    }
  }

}

final class RouteDescription {

  OpenApiObject? returnType;
  Object? requestBody;

  RouteDescription({this.returnType, this.requestBody});

  @override
  String toString() {
    return 'RouteDescription{returnType: $returnType, requestBody: $requestBody}';
  }
  
}

final class RouteResponse {

  OpenApiType responseType;

  Map<String, JsonSchema>? properties;

  RouteResponse({required this.responseType, this.properties});

  Map<String, dynamic> toJson() {
    return {
      ...responseType.toMap(),
      if (properties != null) 'properties': properties,
    };
  }

}