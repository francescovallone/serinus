import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:openapi_types/openapi_types.dart';
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
        final fileResult = await context.currentSession.getFile(filePath);
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
        return staticType.formalParameters.firstOrNull?.type as InterfaceType?;
      }
      return staticType.returnType as InterfaceType?;
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
    for (final entry in additional.exceptions.entries) {
      base.exceptions.putIfAbsent(entry.key, () => entry.value);
    }
    return base;
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
        final descriptor =
            modelTypeSchemas[element] ??
            _buildSchemaDescriptorFromClass(type, visited);
        return wrapNullable(descriptor);
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
