import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import '../analyzer.dart';
import '../models.dart';

/// Visitor that collects exception responses from throw expressions.
class ExceptionCollectorVisitor extends RecursiveAstVisitor<void> {
  /// Constructor
  ExceptionCollectorVisitor(this._analyzer);

  final Analyzer _analyzer;

  /// Map of status codes to exception responses.
  final Map<int, ExceptionResponse> exceptions = {};

  @override
  void visitThrowExpression(ThrowExpression node) {
    final descriptor = _describeException(node.expression);
    if (descriptor != null) {
      exceptions.putIfAbsent(descriptor.statusCode, () => descriptor);
    }
    super.visitThrowExpression(node);
  }

  ExceptionResponse? _describeException(Expression expression) {
    final staticType = expression.staticType;
    if (staticType is! InterfaceType) {
      return null;
    }
    if (!_isSerinusExceptionType(staticType)) {
      return null;
    }
    final classDeclaration = _findClassDeclaration(staticType);
    final constructorName = _constructorNameFromExpression(expression);
    final statusCode = _inferExceptionStatusCode(
      expression,
      staticType,
      classDeclaration,
      constructorName,
    );
    if (statusCode == null) {
      return null;
    }
    final message = _inferExceptionMessage(
      expression,
      staticType,
      classDeclaration,
      constructorName,
    );
    final typeName = staticType.getDisplayString();
    return ExceptionResponse(
      statusCode: statusCode,
      message: message,
      typeName: typeName,
    );
  }

  bool _isSerinusExceptionType(InterfaceType type) {
    return _isSerinusExceptionElement(type.element) ||
        type.allSupertypes.any((e) => _isSerinusExceptionElement(e.element));
  }

  bool _isSerinusExceptionElement(InterfaceElement element) {
    if (element.displayName != 'SerinusException') {
      return false;
    }
    final identifier = element.library.uri.path;
    return identifier.contains('serinus');
  }

  ClassDeclaration? _findClassDeclaration(InterfaceType type) {
    final existing = _analyzer.classDeclarations[type.element];
    if (existing != null) {
      return existing;
    }
    return null;
  }

  String? _constructorNameFromExpression(Expression expression) {
    if (expression is InstanceCreationExpression) {
      final name = expression.constructorName.name;
      return name?.name;
    }
    return null;
  }

  int? _inferExceptionStatusCode(
    Expression expression,
    InterfaceType type,
    ClassDeclaration? classDeclaration,
    String? constructorName,
  ) {
    if (expression is InstanceCreationExpression) {
      final constructor = _findConstructorDeclaration(
        classDeclaration,
        constructorName,
      );
      final fromArgs = _statusCodeFromArgumentList(
        expression.argumentList.arguments,
        constructor,
      );
      if (fromArgs != null) {
        return fromArgs;
      }
      final ctorElement = expression.constructorName.element;
      final fromElement = _statusCodeFromConstructorElement(
        ctorElement,
        visited: <ConstructorElement>{},
      );
      if (fromElement != null) {
        return fromElement;
      }
    }
    return _statusCodeFromClassDeclaration(
      classDeclaration,
      constructorName: constructorName,
      visited: <ConstructorDeclaration>{},
    );
  }

  String? _inferExceptionMessage(
    Expression expression,
    InterfaceType type,
    ClassDeclaration? classDeclaration,
    String? constructorName,
  ) {
    if (expression is InstanceCreationExpression) {
      final constructor = _findConstructorDeclaration(
        classDeclaration,
        constructorName,
      );
      final fromArgs = _messageFromArgumentList(
        expression.argumentList.arguments,
        constructor,
        expression.constructorName.element,
      );
      if (fromArgs != null) {
        return fromArgs;
      }
      if (constructor != null && classDeclaration != null) {
        final fallback = _messageFromConstructorDeclaration(
          constructor,
          classDeclaration,
          <ConstructorDeclaration>{},
        );
        if (fallback != null) {
          return fallback;
        }
      }
    }
    return _messageFromClassDeclaration(
      classDeclaration,
      constructorName: constructorName,
      visited: <ConstructorDeclaration>{},
    );
  }

  int? _statusCodeFromClassDeclaration(
    ClassDeclaration? classDeclaration, {
    required Set<ConstructorDeclaration> visited,
    String? constructorName,
  }) {
    if (classDeclaration == null) {
      return null;
    }
    final constructor = _findConstructorDeclaration(
      classDeclaration,
      constructorName,
    );
    if (constructor == null) {
      return null;
    }
    return _statusCodeFromConstructorDeclaration(
      constructor,
      classDeclaration,
      visited,
    );
  }

  int? _statusCodeFromConstructorDeclaration(
    ConstructorDeclaration constructor,
    ClassDeclaration classDeclaration,
    Set<ConstructorDeclaration> visited,
  ) {
    if (!visited.add(constructor)) {
      return null;
    }
    for (final initializer in constructor.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        final targetName = initializer.constructorName?.name;
        final target = _findConstructorDeclaration(
          classDeclaration,
          targetName,
        );
        final redirected = target != null
            ? _statusCodeFromConstructorDeclaration(
                target,
                classDeclaration,
                visited,
              )
            : null;
        if (redirected != null) {
          return redirected;
        }
      } else if (initializer is SuperConstructorInvocation) {
        final fromSuper = _statusCodeFromSuperInvocation(initializer);
        if (fromSuper != null) {
          return fromSuper;
        }
      }
    }
    return null;
  }

  int? _statusCodeFromConstructorElement(
    ConstructorElement? element, {
    required Set<ConstructorElement> visited,
  }) {
    if (element == null) {
      return null;
    }
    if (!visited.add(element)) {
      return null;
    }

    final redirected = element.redirectedConstructor;
    if (redirected != null) {
      final value = _statusCodeFromConstructorElement(
        redirected,
        visited: visited,
      );
      if (value != null) {
        return value;
      }
    }

    final superConstructor = element.superConstructor;
    if (superConstructor != null) {
      final value = _statusCodeFromConstructorElement(
        superConstructor,
        visited: visited,
      );
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  int? _statusCodeFromArgumentList(
    NodeList<Expression> arguments,
    ConstructorDeclaration? constructor,
  ) {
    for (final argument in arguments) {
      if (argument is NamedExpression && argument.name.label.name == 'statusCode') {
        final value = _evaluateIntConstant(argument.expression);
        if (value != null) {
          return value;
        }
      }
    }
    if (constructor == null) {
      return null;
    }
    final positionalParams = _positionalParameters(constructor);
    var index = 0;
    for (final argument in arguments) {
      if (argument is NamedExpression) {
        continue;
      }
      if (index >= positionalParams.length) {
        break;
      }
      final parameter = positionalParams[index];
      if (_parameterName(parameter) == 'statusCode') {
        final value = _evaluateIntConstant(argument);
        if (value != null) {
          return value;
        }
      }
      index++;
    }
    return null;
  }

  int? _statusCodeFromSuperInvocation(SuperConstructorInvocation invocation) {
    for (final argument in invocation.argumentList.arguments) {
      if (argument is NamedExpression && argument.name.label.name == 'statusCode') {
        final value = _evaluateIntConstant(argument.expression);
        if (value != null) {
          return value;
        }
      }
    }
    return null;
  }

  String? _messageFromClassDeclaration(
    ClassDeclaration? classDeclaration, {
    required Set<ConstructorDeclaration> visited,
    String? constructorName,
  }) {
    if (classDeclaration == null) {
      return null;
    }
    final constructor = _findConstructorDeclaration(
      classDeclaration,
      constructorName,
    );
    if (constructor == null) {
      return null;
    }
    return _messageFromConstructorDeclaration(
      constructor,
      classDeclaration,
      visited,
    );
  }

  String? _messageFromConstructorDeclaration(
    ConstructorDeclaration constructor,
    ClassDeclaration classDeclaration,
    Set<ConstructorDeclaration> visited,
  ) {
    if (!visited.add(constructor)) {
      return null;
    }
    for (final initializer in constructor.initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        final targetName = initializer.constructorName?.name;
        final target = _findConstructorDeclaration(
          classDeclaration,
          targetName,
        );
        final redirected = target != null
            ? _messageFromConstructorDeclaration(
                target,
                classDeclaration,
                visited,
              )
            : null;
        if (redirected != null) {
          return redirected;
        }
      } else if (initializer is SuperConstructorInvocation) {
        final fromSuper = _messageFromSuperInvocation(initializer, constructor);
        if (fromSuper != null) {
          return fromSuper;
        }
      }
    }
    final parameters = constructor.parameters.parameters;
    for (final parameter in parameters) {
      if (_parameterName(parameter) == 'message') {
        final defaultValue = _defaultValueForParameter(parameter);
        if (defaultValue != null) {
          final evaluated = _evaluateStringConstant(defaultValue);
          if (evaluated != null) {
            return evaluated;
          }
        }
      }
    }
    return null;
  }

  ConstructorDeclaration? _findConstructorDeclaration(
    ClassDeclaration? classDeclaration,
    String? constructorName,
  ) {
    if (classDeclaration == null) {
      return null;
    }
    final constructors = classDeclaration.members.whereType<ConstructorDeclaration>().toList();
    if (constructors.isEmpty) {
      return null;
    }
    if (constructorName == null || constructorName.isEmpty) {
      return constructors.firstWhere(
        (ctor) => ctor.name == null,
        orElse: () => constructors.first,
      );
    }
    return constructors.firstWhere(
      (ctor) => ctor.name?.lexeme == constructorName,
      orElse: () => constructors.firstWhere(
        (ctor) => ctor.name == null,
        orElse: () => constructors.first,
      ),
    );
  }

  String? _messageFromArgumentList(
    NodeList<Expression> arguments,
    ConstructorDeclaration? constructor,
    ConstructorElement? constructorElement,
  ) {
    final constructorParameters = constructorElement?.formalParameters ?? [];
    final messageConstructorParameter = constructorParameters.indexed.where((
      element,
    ) {
      return ((element.$2.isPositional == true) || element.$2.isOptionalPositional == true) &&
          element.$2.displayName == 'message';
    }).firstOrNull;
    for (final (index, argument) in arguments.indexed) {
      if (argument is NamedExpression && argument.name.label.name == 'message') {
        final value = _evaluateStringConstant(argument.expression);
        if (value != null) {
          return value;
        }
      }
      if (argument is SimpleStringLiteral &&
          messageConstructorParameter != null &&
          index == messageConstructorParameter.$1) {
        return argument.value;
      }
    }
    if (arguments.isEmpty && messageConstructorParameter != null) {
      final defaultValue = messageConstructorParameter.$2.computeConstantValue();
      return defaultValue?.toStringValue();
    }
    if (constructor == null) {
      return null;
    }
    final positionalParams = _positionalParameters(constructor);
    var index = 0;
    for (final argument in arguments) {
      if (argument is NamedExpression) {
        continue;
      }
      if (index >= positionalParams.length) {
        break;
      }
      final parameter = positionalParams[index];
      if (_parameterName(parameter) == 'message') {
        final value = _evaluateStringConstant(argument);
        if (value != null) {
          return value;
        }
      }
      index++;
    }
    return null;
  }

  String? _messageFromSuperInvocation(
    SuperConstructorInvocation invocation,
    ConstructorDeclaration constructor,
  ) {
    for (final argument in invocation.argumentList.arguments) {
      if (argument is NamedExpression && argument.name.label.name == 'message') {
        final literal = _evaluateStringConstant(argument.expression);
        if (literal != null) {
          return literal;
        }
        final identifier = _identifierName(argument.expression);
        if (identifier != null) {
          final defaultValue = _defaultValueForParameterNamed(
            constructor,
            identifier,
          );
          if (defaultValue != null) {
            final evaluated = _evaluateStringConstant(defaultValue);
            if (evaluated != null) {
              return evaluated;
            }
          }
        }
      }
    }
    return null;
  }

  List<FormalParameter> _positionalParameters(
    ConstructorDeclaration constructor,
  ) {
    final result = <FormalParameter>[];
    for (final parameter in constructor.parameters.parameters) {
      if (!parameter.isNamed) {
        result.add(parameter);
      }
    }
    return result;
  }

  String? _parameterName(FormalParameter parameter) {
    final fragment = parameter.declaredFragment;
    if (fragment != null) {
      return fragment.element.displayName;
    }
    if (parameter is DefaultFormalParameter) {
      return _parameterName(parameter.parameter);
    }
    return null;
  }

  Expression? _defaultValueForParameter(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      return parameter.defaultValue;
    }
    return null;
  }

  Expression? _defaultValueForParameterNamed(
    ConstructorDeclaration constructor,
    String name,
  ) {
    for (final parameter in constructor.parameters.parameters) {
      if (_parameterName(parameter) == name) {
        return _defaultValueForParameter(parameter);
      }
    }
    return null;
  }

  String? _identifierName(Expression expression) {
    if (expression is SimpleIdentifier) {
      return expression.name;
    }
    if (expression is PrefixedIdentifier) {
      return expression.identifier.name;
    }
    return null;
  }

  int? _evaluateIntConstant(Expression expression) {
    if (expression is IntegerLiteral) {
      return expression.value;
    }
    return null;
  }

  String? _evaluateStringConstant(Expression expression) {
    if (expression is SimpleStringLiteral) {
      return expression.value;
    }
    if (expression is AdjacentStrings) {
      final buffer = StringBuffer();
      for (final string in expression.strings) {
        final value = _evaluateStringConstant(string);
        if (value == null) {
          return null;
        }
        buffer.write(value);
      }
      return buffer.toString();
    }
    return null;
  }
}
