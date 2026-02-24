import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:openapi_types/openapi_types.dart';
import '../annotations/open_api_annotation.dart';
import 'models.dart';
import 'visitors/exceptions_visitor.dart';
import 'visitors/models_provider_visitor.dart';
import 'visitors/request_body_visitor.dart';

/// Analyzer class to analyze Dart code and extract OpenAPI route information.
class Analyzer {
  /// The OpenAPI version being used.
  final OpenApiVersion version;

  /// Constructor for [Analyzer].
  Analyzer(this.version);

  /// A map of model types to their schema descriptors.
  final Map<InterfaceElement, SchemaDescriptor> modelTypeSchemas = {};

  /// A set of model provider types.
  final Set<InterfaceElement> modelProviderTypes = {};

  /// A set of registered model providers.
  final Set<InterfaceElement> _registeredModelProviders = {};

  /// A map of class declarations for interface elements.
  final Map<InterfaceElement, ClassDeclaration> classDeclarations = {};

  /// Analyzes the Dart code and extracts route information.
  Future<Map<String, List<RouteDescription>>> analyze([
    int? modificationStamp,
    List<String>? includePaths,
  ]) async {
    modelTypeSchemas.clear();
    modelProviderTypes.clear();
    _registeredModelProviders.clear();
    classDeclarations.clear();
    FileSystemEntity file = Directory.current;
    final collection = AnalysisContextCollection(
      includedPaths: [
        '${file.absolute.path}${Platform.pathSeparator}lib',
        '${file.absolute.path}${Platform.pathSeparator}bin',
        ...?includePaths,
      ],
    );
    final handlersByControllers = <String, List<RouteDescription>>{};
    final libraries = <ResolvedLibraryResult>[];
    for (final context in collection.contexts) {
      final analyzedFiles = context.contextRoot.analyzedFiles();
      for (final filePath in analyzedFiles) {
        if (!filePath.endsWith('.dart') ||
            filePath.endsWith('.g.dart') ||
            filePath
                .replaceAll(file.absolute.path, '')
                .replaceAll('\\', '/')
                .startsWith('/example')) {
          continue;
        }
        final fileResult = context.currentSession.getFile(filePath);
        if (fileResult is FileResult &&
            modificationStamp != null &&
            fileResult.file.exists &&
            fileResult.file.modificationStamp < modificationStamp) {
          continue;
        }
        final result = await context.currentSession.getResolvedLibrary(
          filePath,
        );
        if (result is ResolvedLibraryResult) {
          libraries.add(result);
        }
      }
    }
    for (final library in libraries) {
      final providerCollector = ModelProviderInvocationCollector(
        _resolveInterfaceType,
      );
      for (final unit in library.units) {
        unit.unit.accept(providerCollector);
        for (final declaration in unit.unit.declarations) {
          if (declaration is ClassDeclaration) {
            final element = declaration.declaredFragment;
            if (element != null) {
              classDeclarations[element.element] = declaration;
            }
          }
        }
      }
      for (final providerElement in providerCollector.providers) {
        final declaration = classDeclarations[providerElement];
        if (declaration != null) {
          _registerModelProviderDeclaration(providerElement, declaration);
          classDeclarations.remove(providerElement);
        }
      }
    }
    for (final classDeclaration in classDeclarations.values) {
      final methods = <MethodDeclaration>[];
      final constructors = <ConstructorDeclaration>[];
      final handlers = <String, RouteDescription>{};
      final isController =
          classDeclaration.extendsClause?.superclass.name.value() ==
          'Controller';
      if (!isController) {
        continue;
      }
      String controllerName = '';
      for (final child in classDeclaration.childEntities) {
        if (child is Token && child.type == TokenType.IDENTIFIER) {
          controllerName = child.value().toString();
        }
        if (child is MethodDeclaration) {
          methods.add(child);
        } else if (child is ConstructorDeclaration) {
          constructors.add(child);
          final blockFunctionBody = child.childEntities
              .whereType<BlockFunctionBody>()
              .firstOrNull;
          if (blockFunctionBody != null) {
            final block = blockFunctionBody.block;
            final statements = block.statements
                .whereType<ExpressionStatement>();
            final analyzedHandlers = _analyzeStatements(statements);
            handlers.addAll(analyzedHandlers);
          }
        }
      }
      for (final method in methods) {
        final methodName = method.name.lexeme;
        final savedHandler = handlers[methodName];
        if (savedHandler != null) {
          final analyzed = _analyzeFunctionBody(
            method.body,
            method.parameters!,
          );
          if (analyzed.returnType != null) {
            savedHandler.returnType = analyzed.returnType;
          }
          if (analyzed.requestBody != null) {
            savedHandler.requestBody = analyzed.requestBody;
          }
          if (analyzed.responseContentType != null) {
            savedHandler.responseContentType = analyzed.responseContentType;
          }
          if (analyzed.exceptions.isNotEmpty) {
            for (final entry in analyzed.exceptions.entries) {
              savedHandler.exceptions.putIfAbsent(
                entry.key,
                () => entry.value,
              );
            }
          }
          final annotated = _analyzeMethodAnnotations(method);
          _mergeRouteDescriptions(savedHandler, annotated);
          savedHandler.operationId =
              (savedHandler.operationId ?? analyzed.operationId ?? methodName)
                  .startsWith('_')
              ? (savedHandler.operationId ?? analyzed.operationId ?? methodName)
                    .substring(1)
              : (savedHandler.operationId ??
                    analyzed.operationId ??
                    methodName);
        }
      }
      if (isController) {
        handlersByControllers[controllerName] = handlers.values.toList();
      }
    }
    return handlersByControllers;
  }

  void _registerModelProviderDeclaration(
    InterfaceElement element,
    ClassDeclaration declaration,
  ) {
    if (!_registeredModelProviders.add(element)) {
      return;
    }
    if (!_extendsModelProvider(element)) {
      return;
    }
    final modelTypes = <InterfaceType>{};
    for (final member in declaration.members) {
      if (member is MethodDeclaration && member.isGetter) {
        final name = member.name.lexeme;
        if (name == 'toJsonModels' || name == 'fromJsonModels') {
          modelTypes.addAll(_extractModelTypesFromGetter(member));
        }
      }
    }
    for (final modelType in modelTypes) {
      _registerModelType(modelType);
    }
  }

  Iterable<InterfaceType> _extractModelTypesFromGetter(
    MethodDeclaration getter,
  ) sync* {
    final expression = _extractReturnedExpression(getter.body);
    if (expression is SetOrMapLiteral && expression.isMap) {
      for (final element in expression.elements) {
        if (element is MapLiteralEntry) {
          if (element.key is StringLiteral) {
            final valueType = _resolveInterfaceType(element.value);
            if (valueType != null) {
              yield valueType;
            }
          } else {
            final interface = _resolveInterfaceType(element.key);
            if (interface != null) {
              yield interface;
            }
          }
        }
      }
    }
  }

  Expression? _extractReturnedExpression(FunctionBody body) {
    if (body is ExpressionFunctionBody) {
      return body.expression;
    }
    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is ReturnStatement) {
          return statement.expression;
        }
      }
    }
    return null;
  }

  void _registerModelType(InterfaceType type) {
    final element = type.element;
    if (!modelProviderTypes.add(element)) {
      return;
    }

    final descriptor = _buildSchemaDescriptorFromClass(
      type,
      <InterfaceElement>{},
    );
    modelTypeSchemas[element] = descriptor;
  }

  SchemaDescriptor _buildSchemaDescriptorFromClass(
    InterfaceType type,
    Set<InterfaceElement> visited,
  ) {
    final element = type.element;
    if (!visited.add(element)) {
      return SchemaDescriptor(type: OpenApiType.object());
    }
    final properties = <String, SchemaDescriptor>{};
    for (final field in element.fields) {
      if (field.isStatic ||
          field.isSynthetic ||
          field.displayName.startsWith('_')) {
        continue;
      }
      final descriptor =
          _schemaFromDartTypeInternal(field.type, visited) ??
          SchemaDescriptor(type: OpenApiType.object());
      properties[field.displayName] = descriptor;
    }
    visited.remove(element);
    return SchemaDescriptor(
      type: OpenApiType.object(),
      properties: properties.isEmpty ? null : properties,
    );
  }

  InterfaceType? _resolveInterfaceType(Expression? expression) {
    if (expression == null) {
      return null;
    }

    if (expression is TypeLiteral) {
      final annotationType = expression.type.type;
      if (annotationType is InterfaceType) {
        return annotationType;
      }
    }
    if (expression is ConstructorReference) {
      final type = expression.constructorName.type.element;
      if (type is InterfaceElement) {
        return type.thisType;
      }
    }
    if (expression is Identifier) {
      final element = expression.element;
      if (element is InterfaceElement) {
        return element.thisType;
      }
    }
    if (expression is PrefixedIdentifier) {
      return _resolveInterfaceType(expression.identifier);
    }
    if (expression is PropertyAccess) {
      return _resolveInterfaceType(expression.target);
    }
    final staticType = expression.staticType;
    if (staticType is InterfaceType) {
      final element = staticType.element;
      if (element.library.name == 'dart.core' && element.name == 'Type') {
        return null;
      }
      return staticType;
    }
    if (staticType is FunctionType) {
      if (staticType.returnType.getDisplayString() == 'Map<String, dynamic>') {
        final firstParamType = staticType.formalParameters.firstOrNull?.type;
        if (firstParamType is InterfaceType) {
          return firstParamType;
        }
      }
      if (staticType.returnType is InterfaceType) {
        return staticType.returnType as InterfaceType;
      }
    }
    return null;
  }

  bool _extendsModelProvider(InterfaceElement element) {
    return element.allSupertypes.any(
      (superType) =>
          superType.element.thisType.getDisplayString() == 'ModelProvider',
    );
  }

  Map<String, RouteDescription> _analyzeStatements(
    Iterable<ExpressionStatement> statements,
  ) {
    final handlers = <String, RouteDescription>{};
    for (final statement in statements) {
      if (statement.beginToken.value().toString() == 'ON') {
        final methods = statement.childEntities.whereType<MethodInvocation>();
        final analyzedMethods = _analyzeMethods(methods);
        handlers.addAll(analyzedMethods);
      }
    }
    return handlers;
  }

  Map<String, RouteDescription> _analyzeMethods(
    Iterable<MethodInvocation> methods,
  ) {
    final handlers = <String, RouteDescription>{};
    for (final method in methods) {
      final arguments = method.argumentList.arguments;
      if (arguments.isNotEmpty) {
        handlers.addAll(_analyzeArguments(arguments));
      }
    }
    return handlers;
  }

  Map<String, RouteDescription> _analyzeArguments(
    Iterable<Expression> expressions,
  ) {
    final handlers = <String, RouteDescription>{};
    for (final expr in expressions) {
      if (expr is SimpleIdentifier) {
        handlers[expr.name] = RouteDescription();
      } else if (expr is FunctionExpression) {
        handlers[expr.toSource()] = _analyzeFunctionBody(
          expr.body,
          expr.parameters!,
        );
      }
    }
    return handlers;
  }

  RouteDescription _analyzeFunctionBody(
    FunctionBody body,
    FormalParameterList parameters,
  ) {
    final description = RouteDescription();
    final requestInfo = _extractRequestBody(body);
    if (requestInfo != null) {
      description.requestBody = requestInfo;
    }
    final contextParameter = parameters.parameters.first;
    if (contextParameter is SimpleFormalParameter) {
      final contextType = contextParameter.type as NamedType;
      final typeString = contextType.type?.getDisplayString();
      final genericBody = RegExp(
        r'\<([^)]+)\>',
      ).firstMatch(typeString ?? '');
      if (genericBody != null && genericBody.groupCount == 1) {
        final bodyType = genericBody.group(1);
        final bodyTypeInModelProvider = modelProviderTypes
            .where((e) => e.name == bodyType)
            .firstOrNull;
        if (bodyTypeInModelProvider != null) {
          final dartType = bodyTypeInModelProvider.thisType;
          final descriptor = schemaFromDartType(dartType);
          if (descriptor != null) {
            final isNullable =
                dartType.nullabilitySuffix == NullabilitySuffix.question;
            description.requestBody = RequestBodyInfo(
              schema: descriptor,
              contentType: inferContentType(descriptor),
              isRequired: !isNullable,
            );
          }
        }
      }
    }
    final exceptionResponses = _collectExceptionResponses(body);
    if (exceptionResponses.isNotEmpty) {
      description.exceptions.addAll(exceptionResponses);
    }
    if (body is ExpressionFunctionBody) {
      return _mergeRouteDescriptions(
        description,
        _analyzeReturnType(body.expression),
      );
    }
    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is ReturnStatement) {
          final expression = statement.expression;
          if (expression != null) {
            return _mergeRouteDescriptions(
              description,
              _analyzeReturnType(expression),
            );
          }
          break;
        }
      }
      return description;
    }
    return description;
  }

  RouteDescription _mergeRouteDescriptions(
    RouteDescription base,
    RouteDescription additional,
  ) {
    if (additional.returnType != null) {
      base.returnType = additional.returnType;
    }
    if (additional.requestBody != null) {
      base.requestBody = additional.requestBody;
    }
    if (additional.responseContentType != null) {
      base.responseContentType = additional.responseContentType;
    }
    if (additional.operationId != null) {
      base.operationId = additional.operationId;
    }
    for (final entry in additional.exceptions.entries) {
      base.exceptions.putIfAbsent(entry.key, () => entry.value);
    }
    for (final entry in additional.annotatedResponses.entries) {
      base.annotatedResponses[entry.key] = entry.value;
    }
    for (final entry in additional.annotatedQueryParameters.entries) {
      base.annotatedQueryParameters[entry.key] = entry.value;
    }
    return base;
  }

  RouteDescription _analyzeMethodAnnotations(MethodDeclaration method) {
    var description = RouteDescription();
    for (final annotation in method.metadata) {
      final name = _annotationClassElement(annotation)?.displayName;
      if (name == 'Body') {
        final body = _parseBodyAnnotation(annotation);
        if (body != null) {
          description.requestBody = body;
        }
      }
      if (name == 'Responses') {
        final responses = _parseResponsesAnnotation(annotation);
        description.annotatedResponses.addAll(responses);
      }
      if (name == 'Response') {
        final response = _parseResponseAnnotation(annotation);
        if (response != null) {
          description.annotatedResponses[200] = response;
        }
      }
      if (name == 'Query') {
        final query = _parseQueryAnnotation(annotation);
        if (query.isNotEmpty) {
          description.annotatedQueryParameters.addAll(query);
        }
      }

      final generic = _parseGenericOpenApiAnnotation(annotation);
      if (generic != null) {
        description = _mergeRouteDescriptions(description, generic);
      }
    }
    return description;
  }

  RouteDescription? _parseGenericOpenApiAnnotation(Annotation annotation) {
    final classElement = _annotationClassElement(annotation);
    if (classElement == null || !_isOpenApiAnnotationSubclass(classElement)) {
      return null;
    }

    final constant = annotation.elementAnnotation?.computeConstantValue();
    if (constant == null) {
      return null;
    }

    final kindObject =
        constant.getField('analyzerKind') ??
        constant.getField('kind') ??
        constant.getField('annotationKind');
    final specObject =
        constant.getField('analyzerSpec') ??
        constant.getField('spec') ??
        constant.getField('annotationSpec');

    final kind = _resolveGenericKind(kindObject);
    if (kind == null || kind.isEmpty) {
      return null;
    }

    final normalizedKind = kind.toLowerCase();
    final description = RouteDescription();

    if (normalizedKind == 'body') {
      final body = _parseGenericBodySpec(specObject);
      if (body != null) {
        description.requestBody = body;
      }
      return description;
    }

    if (normalizedKind == 'response') {
      final response = _parseGenericResponseSpec(specObject);
      if (response != null) {
        description.annotatedResponses[200] = response;
      }
      return description;
    }

    if (normalizedKind == 'responses') {
      final responses = _parseGenericResponsesSpec(specObject);
      if (responses.isNotEmpty) {
        description.annotatedResponses.addAll(responses);
      }
      return description;
    }

    if (normalizedKind == 'query') {
      final query = _parseGenericQuerySpec(specObject);
      if (query.isNotEmpty) {
        description.annotatedQueryParameters.addAll(query);
      }
      return description;
    }

    if (normalizedKind == 'operationid') {
      final operationId = _parseGenericOperationIdSpec(specObject);
      if (operationId != null && operationId.isNotEmpty) {
        description.operationId = operationId;
      }
      return description;
    }

    return null;
  }

  String? _resolveGenericKind(DartObject? kindObject) {
    if (kindObject == null) {
      return null;
    }

    final asString = kindObject.toStringValue();
    if (asString != null && asString.isNotEmpty) {
      return asString;
    }

    final enumName = kindObject.getField('name')?.toStringValue();
    if (enumName != null && enumName.isNotEmpty) {
      return enumName;
    }

    final byIndex = kindObject.getField('index')?.toIntValue();
    if (byIndex != null &&
        byIndex >= 0 &&
        byIndex < OpenApiAnnotationKind.values.length) {
      return OpenApiAnnotationKind.values[byIndex].name;
    }

    final fallback = kindObject.toString();
    if (fallback.contains('.')) {
      return fallback.split('.').last;
    }
    return fallback;
  }

  InterfaceElement? _annotationClassElement(Annotation annotation) {
    final element = annotation.elementAnnotation?.element;
    if (element is ConstructorElement) {
      return element.enclosingElement;
    }
    if (element is InterfaceElement) {
      return element;
    }
    return null;
  }

  bool _isOpenApiAnnotationSubclass(InterfaceElement element) {
    if (element.name == 'OpenApiAnnotation') {
      return true;
    }
    return element.allSupertypes.any(
      (type) => type.element.name == 'OpenApiAnnotation',
    );
  }

  RequestBodyInfo? _parseGenericBodySpec(DartObject? specObject) {
    final spec = _asStringKeyMap(specObject);
    if (spec == null) {
      return null;
    }

    final dartType = spec['type']?.toTypeValue();
    if (dartType == null) {
      return null;
    }

    final schema = schemaFromDartType(dartType);
    if (schema == null) {
      return null;
    }

    return RequestBodyInfo(
      schema: schema,
      contentType:
          spec['contentType']?.toStringValue() ?? inferContentType(schema),
      isRequired: spec['required']?.toBoolValue() ?? true,
    );
  }

  OpenApiObject? _parseGenericResponseSpec(DartObject? specObject) {
    final spec = _asStringKeyMap(specObject);
    if (spec == null) {
      return null;
    }

    final description =
        spec['description']?.toStringValue() ?? 'Success response';
    final contentType = spec['contentType']?.toStringValue();
    final responseType = spec['type']?.toTypeValue();

    final schema = responseType == null
        ? null
        : schemaFromDartType(responseType);

    final parsedHeaders = _parseHeadersFromDartObject(spec['headers']);

    switch (version) {
      case OpenApiVersion.v2:
        return ResponseObjectV2(
          description: description,
          schema: schema?.toV2(),
          headers: parsedHeaders.isEmpty
              ? null
              : {
                  for (final entry in parsedHeaders.entries)
                    entry.key: HeaderObjectV2(
                      description: entry.value,
                      type: OpenApiType.string(),
                    ),
                },
        );
      case OpenApiVersion.v3_0:
      case OpenApiVersion.v3_1:
        final resolvedContentType =
            contentType ??
            (schema != null ? inferContentType(schema) : 'application/json');
        return ResponseObjectV3(
          description: description,
          headers: parsedHeaders.isEmpty
              ? null
              : {
                  for (final entry in parsedHeaders.entries)
                    entry.key: HeaderObjectV3(
                      description: entry.value,
                      schema: SchemaObjectV3(type: OpenApiType.string()),
                    ),
                },
          content: schema == null
              ? null
              : {
                  resolvedContentType: MediaTypeObjectV3(
                    schema: schema.toV3(use31: version == OpenApiVersion.v3_1),
                  ),
                },
        );
    }
  }

  /// Extracts a `Map<String, String>` from a [Headers] annotation constant
  /// value, where keys are header names and values are their descriptions.
  Map<String, String> _parseHeadersFromDartObject(DartObject? headersAnnotation) {
    if (headersAnnotation == null) {
      return {};
    }
    final headersMap =
        headersAnnotation.getField('headers')?.toMapValue();
    if (headersMap == null) {
      return {};
    }
    final result = <String, String>{};
    for (final entry in headersMap.entries) {
      final key = entry.key?.toStringValue();
      final value = entry.value?.toStringValue();
      if (key != null && value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  Map<int, OpenApiObject> _parseGenericResponsesSpec(DartObject? specObject) {
    final result = <int, OpenApiObject>{};
    final map = specObject?.toMapValue();
    if (map == null) {
      return result;
    }

    for (final entry in map.entries) {
      final key = entry.key?.toIntValue();
      if (key == null) {
        continue;
      }
      final response = _parseGenericResponseSpec(entry.value);
      if (response != null) {
        result[key] = response;
      }
    }
    return result;
  }

  Map<String, QueryParameterInfo> _parseGenericQuerySpec(
    DartObject? specObject,
  ) {
    final result = <String, QueryParameterInfo>{};
    final map = specObject?.toMapValue();
    if (map == null) {
      return result;
    }

    for (final entry in map.entries) {
      final key = entry.key?.toStringValue();
      if (key == null) {
        continue;
      }

      DartType? dartType = entry.value?.toTypeValue();
      var required = false;
      if (dartType == null) {
        final valueMap = _asStringKeyMap(entry.value);
        dartType = valueMap?['type']?.toTypeValue();
        required = valueMap?['required']?.toBoolValue() ?? false;
      }
      if (dartType == null) {
        continue;
      }

      final schema = schemaFromDartType(dartType);
      if (schema != null) {
        result[key] = QueryParameterInfo(schema: schema, required: required);
      }
    }
    return result;
  }

  Map<String, QueryParameterInfo> _parseQueryAnnotation(Annotation annotation) {
    final result = <String, QueryParameterInfo>{};
    final args = annotation.arguments?.arguments;
    if (args == null || args.isEmpty) {
      return result;
    }

    final first = args.first;
    if (first is! ListLiteral) {
      return result;
    }

    for (final element in first.elements) {
      if (element is! InstanceCreationExpression) {
        continue;
      }
      final typeName = element.constructorName.type.name.lexeme;
      if (typeName != 'QueryParameter') {
        continue;
      }

      final queryArgs = element.argumentList.arguments;
      if (queryArgs.length < 2) {
        continue;
      }

      final name = _stringFromExpression(queryArgs[0]);
      final typeString = _stringFromExpression(queryArgs[1]);
      if (name == null || typeString == null) {
        continue;
      }

      var required = false;
      for (final queryArg in queryArgs.whereType<NamedExpression>()) {
        if (queryArg.name.label.name == 'required') {
          required = _boolFromExpression(queryArg.expression) ?? required;
        }
      }

      final schema = _schemaFromQueryTypeString(typeString);
      if (schema != null) {
        result[name] = QueryParameterInfo(schema: schema, required: required);
      }
    }

    return result;
  }

  SchemaDescriptor? _schemaFromQueryTypeString(String type) {
    switch (type.toLowerCase()) {
      case 'string':
        return SchemaDescriptor(type: OpenApiType.string());
      case 'integer':
      case 'int':
      case 'int32':
        return SchemaDescriptor(type: OpenApiType.int32());
      case 'number':
      case 'double':
      case 'float':
        return SchemaDescriptor(type: OpenApiType.double());
      case 'boolean':
      case 'bool':
        return SchemaDescriptor(type: OpenApiType.boolean());
      case 'array':
        return SchemaDescriptor(
          type: OpenApiType.array(),
          items: SchemaDescriptor(type: OpenApiType.string()),
        );
      case 'object':
        return SchemaDescriptor(type: OpenApiType.object());
      default:
        return null;
    }
  }

  String? _parseGenericOperationIdSpec(DartObject? specObject) {
    final direct = specObject?.toStringValue();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final map = _asStringKeyMap(specObject);
    final value = map?['value']?.toStringValue();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  Map<String, DartObject?>? _asStringKeyMap(DartObject? object) {
    final raw = object?.toMapValue();
    if (raw == null) {
      return null;
    }
    final result = <String, DartObject?>{};
    for (final entry in raw.entries) {
      final key = entry.key?.toStringValue();
      if (key == null) {
        continue;
      }
      result[key] = entry.value;
    }
    return result;
  }

  RequestBodyInfo? _parseBodyAnnotation(Annotation annotation) {
    final args = annotation.arguments?.arguments;
    if (args == null || args.isEmpty) {
      return null;
    }

    InterfaceType? type;
    SchemaDescriptor? fallbackSchema;
    String? contentType;
    bool required = true;

    for (final arg in args) {
      if (arg is! NamedExpression) {
        final resolved = _resolveInterfaceType(arg);
        if (resolved != null) {
          type = resolved;
        } else {
          fallbackSchema = _schemaFromTypeExpression(arg) ?? fallbackSchema;
        }
        continue;
      }
      final label = arg.name.label.name;
      if (label == 'contentType') {
        final value = _stringFromExpression(arg.expression);
        if (value != null) {
          contentType = value;
        }
      }
      if (label == 'required') {
        final value = _boolFromExpression(arg.expression);
        if (value != null) {
          required = value;
        }
      }
    }

    if (type == null && fallbackSchema == null) {
      return null;
    }

    final schema = type != null ? schemaFromDartType(type) : fallbackSchema;
    if (schema == null) {
      return null;
    }

    return RequestBodyInfo(
      schema: schema,
      contentType: contentType ?? inferContentType(schema),
      isRequired: required,
    );
  }

  Map<int, OpenApiObject> _parseResponsesAnnotation(Annotation annotation) {
    final result = <int, OpenApiObject>{};
    final args = annotation.arguments?.arguments;
    if (args == null || args.isEmpty) {
      return result;
    }
    final first = args.first;
    if (first is! SetOrMapLiteral || !first.isMap) {
      return result;
    }

    for (final element in first.elements) {
      if (element is! MapLiteralEntry) {
        continue;
      }
      final status = _intFromExpression(element.key);
      if (status == null) {
        continue;
      }
      final response = _parseResponseExpression(element.value);
      if (response != null) {
        result[status] = response;
      }
    }
    return result;
  }

  OpenApiObject? _parseResponseAnnotation(Annotation annotation) {
    final constructorName = annotation.constructorName?.name;
    if (constructorName != null &&
        constructorName != 'schema' &&
        constructorName != 'oneOf') {
      return null;
    }
    return _buildResponseFromArguments(
      annotation.arguments?.arguments ?? const <Expression>[],
      constructorName: constructorName,
    );
  }

  OpenApiObject? _parseResponseExpression(Expression expression) {
    if (expression is! InstanceCreationExpression) {
      return null;
    }
    final typeName = expression.constructorName.type.name.lexeme;
    if (typeName != 'Response') {
      return null;
    }
    final constructorName = expression.constructorName.name?.name;
    return _buildResponseFromArguments(
      expression.argumentList.arguments,
      constructorName: constructorName,
    );
  }

  OpenApiObject? _buildResponseFromArguments(
    Iterable<Expression> arguments, {
    String? constructorName,
  }) {
    if (constructorName == 'oneOf') {
      return _buildOneOfResponseFromArguments(arguments);
    }
    String description = 'Success response';
    InterfaceType? responseType;
    SchemaDescriptor? fallbackSchema;
    String? contentType;
    var parsedHeaders = <String, String>{};

    for (final arg in arguments) {
      if (arg is! NamedExpression) {
        continue;
      }
      final label = arg.name.label.name;
      if (label == 'description') {
        final value = _stringFromExpression(arg.expression);
        if (value != null) {
          description = value;
        }
      } else if (label == 'type') {
        responseType = _resolveInterfaceType(arg.expression) ?? responseType;
        fallbackSchema =
            _schemaFromTypeExpression(arg.expression) ?? fallbackSchema;
      } else if (label == 'contentType') {
        final value = _stringFromExpression(arg.expression);
        if (value != null) {
          contentType = value;
        }
      } else if (label == 'headers') {
        parsedHeaders = _parseHeadersToStringMap(arg.expression);
      }
    }

    SchemaDescriptor? schema;
    if (responseType != null) {
      schema = schemaFromDartType(responseType);
    }
    schema ??= fallbackSchema;

    switch (version) {
      case OpenApiVersion.v2:
        return ResponseObjectV2(
          description: description,
          schema: schema?.toV2(),
          headers: parsedHeaders.isEmpty
              ? null
              : {
                  for (final entry in parsedHeaders.entries)
                    entry.key: HeaderObjectV2(
                      description: entry.value,
                      type: OpenApiType.string(),
                    ),
                },
        );
      case OpenApiVersion.v3_0:
      case OpenApiVersion.v3_1:
        final resolvedContentType =
            contentType ??
            (schema != null ? inferContentType(schema) : 'application/json');
        return ResponseObjectV3(
          description: description,
          headers: parsedHeaders.isEmpty
              ? null
              : {
                  for (final entry in parsedHeaders.entries)
                    entry.key: HeaderObjectV3(
                      description: entry.value,
                      schema: SchemaObjectV3(type: OpenApiType.string()),
                    ),
                },
          content: schema == null
              ? null
              : {
                  resolvedContentType: MediaTypeObjectV3(
                    schema: schema.toV3(use31: version == OpenApiVersion.v3_1),
                  ),
                },
        );
    }
  }

  /// Builds a response object from a [Response.oneOf] constructor argument list.
  OpenApiObject? _buildOneOfResponseFromArguments(
    Iterable<Expression> arguments,
  ) {
    String description = 'Success response';
    String? contentType;
    var parsedHeaders = <String, String>{};
    final oneOfSchemas = <SchemaDescriptor>[];

    for (final arg in arguments) {
      if (arg is! NamedExpression) {
        continue;
      }
      final label = arg.name.label.name;
      if (label == 'description') {
        final value = _stringFromExpression(arg.expression);
        if (value != null) {
          description = value;
        }
      } else if (label == 'types') {
        if (arg.expression is ListLiteral) {
          for (final element
              in (arg.expression as ListLiteral).elements) {
            if (element is! Expression) {
              continue;
            }
            final interfaceType = _resolveInterfaceType(element);
            if (interfaceType != null) {
              // Ensure the type is registered as a component schema so that
              // schemaFromDartType returns a ReferenceObject ($ref) instead of
              // an inline SchemaObjectV3, which is not accepted in oneOf.
              _registerModelType(interfaceType);
            }
            final schema = interfaceType != null
                ? schemaFromDartType(interfaceType)
                : _schemaFromTypeExpression(element);
            if (schema != null) {
              oneOfSchemas.add(schema);
            }
          }
        }
      } else if (label == 'contentType') {
        final value = _stringFromExpression(arg.expression);
        if (value != null) {
          contentType = value;
        }
      } else if (label == 'headers') {
        parsedHeaders = _parseHeadersToStringMap(arg.expression);
      }
    }

    if (oneOfSchemas.isEmpty) {
      return null;
    }

    final oneOfSchema = SchemaDescriptor(
      type: OpenApiType.object(),
      oneOf: oneOfSchemas,
    );
    final resolvedContentType = contentType ?? 'application/json';

    switch (version) {
      case OpenApiVersion.v2:
        return ResponseObjectV2(
          description: description,
          schema: oneOfSchema.toV2(),
          headers: parsedHeaders.isEmpty
              ? null
              : {
                  for (final entry in parsedHeaders.entries)
                    entry.key: HeaderObjectV2(
                      description: entry.value,
                      type: OpenApiType.string(),
                    ),
                },
        );
      case OpenApiVersion.v3_0:
      case OpenApiVersion.v3_1:
        return ResponseObjectV3(
          description: description,
          headers: parsedHeaders.isEmpty
              ? null
              : {
                  for (final entry in parsedHeaders.entries)
                    entry.key: HeaderObjectV3(
                      description: entry.value,
                      schema: SchemaObjectV3(type: OpenApiType.string()),
                    ),
                },
          content: {
            resolvedContentType: MediaTypeObjectV3(
              schema: oneOfSchema.toV3(
                use31: version == OpenApiVersion.v3_1,
              ),
            ),
          },
        );
    }
  }

  /// Parses a [Headers] annotation expression into a plain `Map<String, String>`
  /// where keys are header names and values are descriptions.
  Map<String, String> _parseHeadersToStringMap(Expression expression) {
    if (expression is! InstanceCreationExpression) {
      return {};
    }
    final typeName = expression.constructorName.type.name.lexeme;
    if (typeName != 'Headers') {
      return {};
    }
    final args = expression.argumentList.arguments;
    if (args.isEmpty) {
      return {};
    }
    final first = args.first;
    if (first is! SetOrMapLiteral || !first.isMap) {
      return {};
    }
    final result = <String, String>{};
    for (final element in first.elements) {
      if (element is! MapLiteralEntry) {
        continue;
      }
      final key = _stringFromExpression(element.key);
      final value = _stringFromExpression(element.value);
      if (key != null && value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  String? _stringFromExpression(Expression expression) {
    final normalized = _normalizeExpression(expression);
    if (normalized is SimpleStringLiteral) {
      return normalized.value;
    }
    return null;
  }

  bool? _boolFromExpression(Expression expression) {
    final normalized = _normalizeExpression(expression);
    if (normalized is BooleanLiteral) {
      return normalized.value;
    }
    return null;
  }

  int? _intFromExpression(Expression expression) {
    final normalized = _normalizeExpression(expression);
    if (normalized is IntegerLiteral) {
      return normalized.value;
    }
    return null;
  }

  SchemaDescriptor? _schemaFromTypeExpression(Expression expression) {
    final source = _normalizeTypeSource(expression.toSource());
    if (source.isEmpty) {
      return null;
    }
    return _schemaFromTypeSource(source);
  }

  String _normalizeTypeSource(String source) {
    var result = source.replaceAll(' ', '');
    if (result.endsWith('?')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  SchemaDescriptor? _schemaFromTypeSource(String source) {
    if (source == 'String') {
      return SchemaDescriptor(type: OpenApiType.string());
    }
    if (source == 'int') {
      return SchemaDescriptor(type: OpenApiType.int32());
    }
    if (source == 'double' || source == 'num') {
      return SchemaDescriptor(type: OpenApiType.double());
    }
    if (source == 'bool') {
      return SchemaDescriptor(type: OpenApiType.boolean());
    }

    if (source.startsWith('List<') && source.endsWith('>')) {
      final inner = source.substring(5, source.length - 1);
      return SchemaDescriptor(
        type: OpenApiType.array(),
        items:
            _schemaFromTypeSource(inner) ??
            SchemaDescriptor(type: OpenApiType.object()),
      );
    }

    if (source.startsWith('Map<')) {
      return SchemaDescriptor(
        type: OpenApiType.object(),
        additionalProperties: SchemaDescriptor(type: OpenApiType.object()),
      );
    }

    final simpleName = source.contains('.') ? source.split('.').last : source;

    if (simpleName.endsWith('Exception')) {
      final defaultExample = builtInExceptionsMap[simpleName]?.$2;
      return _schemaForSerinusException(defaultExample);
    }

    final model = modelProviderTypes
        .where((e) => e.name == simpleName)
        .firstOrNull;
    if (model != null) {
      return SchemaDescriptor.ref('#/components/schemas/$simpleName');
    }

    return null;
  }

  RequestBodyInfo? _extractRequestBody(FunctionBody body) {
    final visitor = RequestBodyVisitor(this);
    body.accept(visitor);
    return visitor.result;
  }

  Map<int, ExceptionResponse> _collectExceptionResponses(FunctionBody body) {
    final visitor = ExceptionCollectorVisitor(this);
    body.accept(visitor);
    return visitor.exceptions;
  }

  RouteDescription _analyzeReturnType(Expression expr) {
    final description = RouteDescription();
    final responseBody = _resolveResponseBody(expr);
    if (responseBody == null) {
      return description;
    }

    description.responseContentType = responseBody.contentType;

    switch (version) {
      case OpenApiVersion.v2:
        description.returnType = ResponseObjectV2(
          description: 'Success response',
          schema: responseBody.schema.toV2(),
        );
        break;
      case OpenApiVersion.v3_0:
      case OpenApiVersion.v3_1:
        final schema = responseBody.schema.toV3(
          use31: version == OpenApiVersion.v3_1,
        );
        description.returnType = ResponseObjectV3(
          description: 'Success response',
          content: {
            responseBody.contentType: MediaTypeObjectV3(schema: schema),
          },
        );
        break;
    }
    return description;
  }

  ResponseBody? _resolveResponseBody(Expression expression) {
    final normalized = _normalizeExpression(expression);
    if (normalized is ThrowExpression) {
      return null;
    }
    final schema = _inferSchemaFromExpression(normalized);
    if (schema == null) {
      return null;
    }
    final contentType = inferContentType(schema);
    return ResponseBody(schema: schema, contentType: contentType);
  }

  Expression _normalizeExpression(Expression expression) {
    Expression current = expression;
    while (true) {
      if (current is ParenthesizedExpression) {
        current = current.expression;
        continue;
      }
      if (current is AsExpression) {
        current = current.expression;
        continue;
      }
      break;
    }
    return current;
  }

  SchemaDescriptor? _inferSchemaFromExpression(Expression expression) {
    final expr = _normalizeExpression(expression);
    if (expr is AwaitExpression) {
      return _inferSchemaFromExpression(expr.expression);
    }
    if (expr is NullLiteral) {
      return null;
    }
    if (expr is SetOrMapLiteral) {
      return expr.isMap
          ? _schemaForMapLiteral(expr)
          : _schemaForSetLiteral(expr);
    }
    if (expr is ListLiteral) {
      return _schemaForListLiteral(expr);
    }
    if (expr is SimpleStringLiteral ||
        expr is AdjacentStrings ||
        expr is StringInterpolation) {
      return SchemaDescriptor(type: OpenApiType.string());
    }
    if (expr is IntegerLiteral) {
      return SchemaDescriptor(type: OpenApiType.int32());
    }
    if (expr is DoubleLiteral) {
      return SchemaDescriptor(type: OpenApiType.double());
    }
    if (expr is BooleanLiteral) {
      return SchemaDescriptor(type: OpenApiType.boolean());
    }
    if (expr is ConditionalExpression) {
      final thenDescriptor = _inferSchemaFromExpression(expr.thenExpression);
      final elseDescriptor = _inferSchemaFromExpression(expr.elseExpression);
      return _mergeSchemaDescriptors(thenDescriptor, elseDescriptor);
    }
    if (expr is InstanceCreationExpression) {
      final type = expr.staticType;
      if (type is InterfaceType && _isRedirectType(type)) {
        return null;
      }
    }

    return schemaFromDartType(expr.staticType) ??
        SchemaDescriptor(type: OpenApiType.object());
  }

  SchemaDescriptor _schemaForMapLiteral(SetOrMapLiteral literal) {
    final properties = <String, SchemaDescriptor>{};
    for (final element in literal.elements) {
      if (element is! MapLiteralEntry) {
        continue;
      }
      final key = _mapKeyToString(element.key);
      final valueDescriptor =
          _inferSchemaFromExpression(element.value) ??
          SchemaDescriptor(type: OpenApiType.object());
      properties[key] = valueDescriptor;
    }
    return SchemaDescriptor(
      type: OpenApiType.object(),
      properties: properties.isEmpty ? null : properties,
    );
  }

  SchemaDescriptor _schemaForSetLiteral(SetOrMapLiteral literal) {
    final descriptors = <SchemaDescriptor>[];
    for (final element in literal.elements) {
      if (element is! Expression) {
        continue;
      }
      final descriptor = _inferSchemaFromExpression(element);
      if (descriptor != null) {
        descriptors.add(descriptor);
      }
    }
    final itemDescriptor = descriptors.isEmpty
        ? SchemaDescriptor(type: OpenApiType.string())
        : descriptors.first;
    return SchemaDescriptor(type: OpenApiType.array(), items: itemDescriptor);
  }

  SchemaDescriptor _schemaForListLiteral(ListLiteral literal) {
    final descriptors = <SchemaDescriptor>[];
    for (final element in literal.elements) {
      if (element is! Expression) {
        continue;
      }
      final descriptor = _inferSchemaFromExpression(element);
      if (descriptor != null) {
        descriptors.add(descriptor);
      }
    }
    SchemaDescriptor itemDescriptor;
    if (descriptors.isEmpty) {
      itemDescriptor = SchemaDescriptor(type: OpenApiType.object());
    } else {
      itemDescriptor = descriptors.first;
      final homogeneous = descriptors.every(
        (candidate) => candidate.type == itemDescriptor.type,
      );
      if (!homogeneous) {
        itemDescriptor = SchemaDescriptor(type: OpenApiType.object());
      }
    }
    return SchemaDescriptor(type: OpenApiType.array(), items: itemDescriptor);
  }

  String _mapKeyToString(Expression key) {
    if (key is SimpleStringLiteral) {
      return key.value;
    }
    if (key is IntegerLiteral) {
      return key.value?.toString() ?? 'null';
    }
    if (key is BooleanLiteral) {
      return key.value.toString();
    }
    if (key is SimpleIdentifier) {
      return key.name;
    }
    return key.toSource();
  }

  /// Converts a Dart type to a schema descriptor.
  SchemaDescriptor? schemaFromDartType(DartType? type) {
    return _schemaFromDartTypeInternal(type, <InterfaceElement>{});
  }

  SchemaDescriptor? _schemaFromDartTypeInternal(
    DartType? type,
    Set<InterfaceElement> visited,
  ) {
    if (type == null) {
      return null;
    }
    final display = type.getDisplayString();
    final nullable = type.nullabilitySuffix == NullabilitySuffix.question;
    final coreDisplay = nullable
        ? display.substring(0, display.length - 1)
        : display;

    SchemaDescriptor? wrapNullable(SchemaDescriptor? descriptor) {
      if (descriptor == null) {
        return null;
      }
      return nullable ? descriptor.asNullable() : descriptor;
    }

    if (coreDisplay == 'void' || coreDisplay == 'Never') {
      return null;
    }

    if (type is TypeParameterType) {
      return wrapNullable(_schemaFromDartTypeInternal(type.bound, visited));
    }

    if (coreDisplay.startsWith('Future<')) {
      final inner = _schemaFromDartTypeInternal(
        type is InterfaceType && type.typeArguments.isNotEmpty
            ? type.typeArguments.first
            : null,
        visited,
      );
      return wrapNullable(inner);
    }

    if (type is InterfaceType) {
      final element = type.element;
      if (modelProviderTypes.where((e) => e.name == coreDisplay).isNotEmpty) {
        modelTypeSchemas.putIfAbsent(
          element,
          () => _buildSchemaDescriptorFromClass(type, visited),
        );
        return wrapNullable(
          SchemaDescriptor.ref('#/components/schemas/${element.name}'),
        );
      }

      if (_isRedirectType(type)) {
        return null;
      }

      if (_isFutureInterface(type)) {
        final typeArgument = type.typeArguments.isNotEmpty
            ? type.typeArguments.first
            : null;
        return wrapNullable(_schemaFromDartTypeInternal(typeArgument, visited));
      }
      if (_isStreamInterface(type)) {
        final typeArgument = type.typeArguments.isNotEmpty
            ? type.typeArguments.first
            : null;
        final itemsDescriptor = _schemaFromDartTypeInternal(
          typeArgument,
          visited,
        );
        return wrapNullable(
          SchemaDescriptor(type: OpenApiType.array(), items: itemsDescriptor),
        );
      }
      if (_isUint8List(type) || _isListOfBytes(type)) {
        return wrapNullable(SchemaDescriptor(type: OpenApiType.binary()));
      }
      if (type.isDartCoreString) {
        return wrapNullable(SchemaDescriptor(type: OpenApiType.string()));
      }
      if (type.isDartCoreInt) {
        return wrapNullable(SchemaDescriptor(type: OpenApiType.int32()));
      }
      if (type.isDartCoreDouble) {
        return wrapNullable(SchemaDescriptor(type: OpenApiType.double()));
      }
      if (type.isDartCoreNum) {
        return wrapNullable(SchemaDescriptor(type: OpenApiType.double()));
      }
      if (type.isDartCoreBool) {
        return wrapNullable(SchemaDescriptor(type: OpenApiType.boolean()));
      }
      if (_isDateTime(type)) {
        return wrapNullable(SchemaDescriptor(type: OpenApiType.dateTime()));
      }
      if (type.isDartCoreList || _implementsIterable(type)) {
        final typeArgument = type.typeArguments.isNotEmpty
            ? type.typeArguments.first
            : null;
        final itemsDescriptor = _schemaFromDartTypeInternal(
          typeArgument,
          visited,
        );
        return wrapNullable(
          SchemaDescriptor(type: OpenApiType.array(), items: itemsDescriptor),
        );
      }
      if (type.isDartCoreMap) {
        final valueType = type.typeArguments.length > 1
            ? type.typeArguments[1]
            : null;
        final valueDescriptor = _schemaFromDartTypeInternal(valueType, visited);
        return wrapNullable(
          SchemaDescriptor(
            type: OpenApiType.object(),
            additionalProperties: valueDescriptor,
          ),
        );
      }
      if (_isSerinusExceptionType(type)) {
        final exName = type.element.displayName;
        final defaultExample = builtInExceptionsMap[exName]?.$2 ??
            builtInExceptionsMap.entries
                .where(
                  (e) => type.allSupertypes.any(
                    (s) => s.element.displayName == e.key,
                  ),
                )
                .map((e) => e.value.$2)
                .firstOrNull;
        return wrapNullable(_schemaForSerinusException(defaultExample));
      }
      if (_implementsJsonObject(type)) {
        return wrapNullable(
          SchemaDescriptor(
            type: OpenApiType.object(),
            properties: _generatePropertiesFromJsonObject(type, visited),
          ),
        );
      }
      return wrapNullable(SchemaDescriptor(type: OpenApiType.object()));
    }

    if (coreDisplay == 'dynamic') {
      return SchemaDescriptor(type: OpenApiType.object(), nullable: true);
    }

    return wrapNullable(SchemaDescriptor(type: OpenApiType.object()));
  }

  SchemaDescriptor? _mergeSchemaDescriptors(
    SchemaDescriptor? a,
    SchemaDescriptor? b,
  ) {
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    if (a.type == b.type) {
      if (a.ref != null || b.ref != null) {
        if (a.ref != null && a.ref == b.ref) {
          return SchemaDescriptor.ref(a.ref).asNullable();
        }
        return SchemaDescriptor(type: OpenApiType.object());
      }
      if (a.type == OpenApiType.object()) {
        final merged = <String, SchemaDescriptor>{};
        for (final entry
            in a.properties?.entries ??
                <MapEntry<String, SchemaDescriptor>>[]) {
          merged[entry.key] = entry.value;
        }
        for (final entry
            in b.properties?.entries ??
                <MapEntry<String, SchemaDescriptor>>[]) {
          merged.putIfAbsent(entry.key, () => entry.value);
        }
        return SchemaDescriptor(
          type: a.type,
          properties: merged.isEmpty ? null : merged,
          nullable: a.nullable || b.nullable,
        );
      }
      if (a.type == OpenApiType.array()) {
        final mergedItems = _mergeSchemaDescriptors(a.items, b.items);
        return SchemaDescriptor(
          type: a.type,
          items: mergedItems,
          nullable: a.nullable || b.nullable,
        );
      }
      return SchemaDescriptor(type: a.type, nullable: a.nullable || b.nullable);
    }
    return SchemaDescriptor(type: OpenApiType.object());
  }

  /// Infers the content type for a given schema descriptor.
  String inferContentType(SchemaDescriptor schema) {
    if (schema.ref != null) {
      return 'application/json';
    }
    if (schema.type == OpenApiType.binary()) {
      return 'application/octet-stream';
    }
    if (schema.type == OpenApiType.object() ||
        schema.type == OpenApiType.array()) {
      return 'application/json';
    }
    return 'text/plain';
  }

  bool _isUint8List(InterfaceType type) {
    final element = type.element;
    return element.displayName == 'Uint8List' &&
        element.library.displayName == 'dart.typed_data';
  }

  bool _isFutureInterface(InterfaceType type) {
    final element = type.element;
    return element.displayName == 'Future' &&
        element.library.displayName == 'dart.async';
  }

  bool _isStreamInterface(InterfaceType type) {
    final element = type.element;
    return element.displayName == 'Stream' &&
        element.library.displayName == 'dart.async';
  }

  bool _isListOfBytes(InterfaceType type) {
    if (!type.isDartCoreList) {
      return false;
    }
    if (type.typeArguments.isEmpty) {
      return false;
    }
    final argument = type.typeArguments.first;
    return argument is InterfaceType && argument.isDartCoreInt;
  }

  bool _implementsIterable(InterfaceType type) {
    if (type.isDartCoreIterable) {
      return true;
    }
    return type.allSupertypes.any((superType) => superType.isDartCoreIterable);
  }

  bool _implementsJsonObject(InterfaceType type) {
    return type.element.interfaces.any(
          (iface) => iface.element.displayName == 'JsonObject',
        ) ||
        type.element.mixins.any(
          (mixin) => mixin.element.displayName == 'JsonObject',
        ) ||
        type.allSupertypes.any(
          (superType) => superType.element.displayName == 'JsonObject',
        ) ||
        type.methods.any(
          (method) =>
              method.displayName == 'toJson' ||
              method.displayName == 'fromJson',
        );
  }

  bool _isSerinusExceptionType(InterfaceType type) {
    bool isSerinusExceptionElement(InterfaceElement element) {
      if (element.displayName != 'SerinusException') {
        return false;
      }
      return element.library.uri.path.contains('serinus');
    }

    return isSerinusExceptionElement(type.element) ||
        type.allSupertypes.any((e) => isSerinusExceptionElement(e.element));
  }

  SchemaDescriptor _schemaForSerinusException([
    Map<String, dynamic>? example,
  ]) {
    return SchemaDescriptor(
      type: OpenApiType.object(),
      properties: {
        'message': SchemaDescriptor(type: OpenApiType.string()),
        'statusCode': SchemaDescriptor(type: OpenApiType.int32()),
        'uri': SchemaDescriptor(type: OpenApiType.string()),
      },
      example: example,
    );
  }

  bool _isRedirectType(InterfaceType type) {
    return type.element.displayName == 'Redirect';
  }

  bool _isDateTime(InterfaceType type) {
    final element = type.element;
    return element.displayName == 'DateTime' &&
        element.library.displayName == 'dart.core';
  }

  Map<String, SchemaDescriptor>? _generatePropertiesFromJsonObject(
    InterfaceType type,
    Set<InterfaceElement> visited,
  ) {
    final element = type.element;
    final properties = <String, SchemaDescriptor>{};
    for (final field in element.fields) {
      if (field.isStatic ||
          field.isSynthetic ||
          field.displayName.startsWith('_')) {
        continue;
      }
      final descriptor =
          _schemaFromDartTypeInternal(field.type, visited) ??
          SchemaDescriptor(type: OpenApiType.object());
      properties[field.displayName] = descriptor;
    }
    return properties.isEmpty ? null : properties;
  }
}
