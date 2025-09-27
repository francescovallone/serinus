import 'package:acanthis/acanthis.dart';

import '../contexts/contexts.dart';
import '../exceptions/exceptions.dart';
import '../http/http.dart';
import 'core.dart';

/// Represents a pipe in the request processing pipeline.
abstract class Pipe extends Processable {
  /// The [Pipe] constructor is used to create a [Pipe] object.
  const Pipe();

  /// Transform and validate the input data
  Future<void> transform(ExecutionContext context);
}

/// Represents a body schema validation pipe.
class BodySchemaValidationPipe<T extends Body> extends Pipe {
  /// The schema to validate against.
  final AcanthisType schema;

  /// Function to handle validation errors.
  final SerinusException Function(String key, ValidationError error)? onError;

  /// Creates a new instance of [BodySchemaValidationPipe].
  const BodySchemaValidationPipe(this.schema, {this.onError});

  @override
  Future<void> transform(ExecutionContext context) async {
    final argsHost = context.argumentsHost;
    if (argsHost is! HttpArgumentsHost) {
      return;
    }
    try {
      final reqContext = context.switchToHttp();
      final result = schema.parse(reqContext.body.value);
      switch (schema) {
        case AcanthisMap():
          reqContext.body = JsonBody.fromJson(
            result.value as Map<String, dynamic>,
          );
          break;
        case AcanthisList():
          reqContext.body = JsonBody.fromJson(result.value as List<dynamic>);
          break;
        case AcanthisType():
          reqContext.body = TextBody(result.value.toString());
      }
    } on ValidationError catch (e) {
      throw onError?.call(e.key, e) ?? BadRequestException('$e');
    }
  }
}

/// Enum representing the type of binding for a pipe.
enum PipeBindingType {
  /// Bind to request query parameters.
  query,

  /// Bind to request URL parameters.
  params,
}

/// Represents a date parsing pipe.
class ParseDatePipe extends Pipe {
  /// The key to look for in the request.
  final String key;

  /// The binding type of the pipe.
  final PipeBindingType bindingType;

  /// Function to handle errors during parsing.
  final SerinusException Function(String key)? onError;

  /// Creates a new instance of [ParseDatePipe].
  ParseDatePipe(this.key, {required this.bindingType, this.onError});

  @override
  Future<void> transform(ExecutionContext context) async {
    final argsHost = context.argumentsHost;
    if (argsHost is! HttpArgumentsHost) {
      return;
    }
    if (bindingType == PipeBindingType.params) {
      final dateValue = DateTime.tryParse(argsHost.params[key] ?? '');
      if (dateValue == null) {
        throw onError?.call(key) ??
            BadRequestException('Invalid parameter: $key');
      }
      argsHost.params[key] = dateValue;
    }
    if (bindingType == PipeBindingType.query) {
      final dateValue = DateTime.tryParse(
        argsHost.query[key]?.toString() ?? '',
      );
      if (dateValue == null) {
        throw onError?.call(key) ??
            BadRequestException('Invalid query parameter: $key');
      }
      argsHost.request.query[key] = dateValue;
    }
  }
}

/// Represents a double parsing pipe.
class ParseDoublePipe extends Pipe {
  /// The key to look for in the request.
  final String key;

  /// The binding type of the pipe.
  final PipeBindingType bindingType;

  /// Function to handle errors during parsing.
  final SerinusException Function(String key)? onError;

  /// Creates a new instance of [ParseDoublePipe].
  ParseDoublePipe(this.key, {required this.bindingType, this.onError});

  @override
  Future<void> transform(ExecutionContext context) async {
    final argsHost = context.argumentsHost;
    if (argsHost is! HttpArgumentsHost) {
      return;
    }
    if (bindingType == PipeBindingType.params) {
      final doubleValue = double.tryParse(argsHost.params[key] ?? '');
      if (doubleValue == null) {
        throw onError?.call(key) ??
            BadRequestException('Invalid parameter: $key');
      }
      argsHost.params[key] = doubleValue;
    }
    if (bindingType == PipeBindingType.query) {
      final doubleValue = double.tryParse(
        argsHost.query[key]?.toString() ?? '',
      );
      if (doubleValue == null) {
        throw onError?.call(key) ??
            BadRequestException('Invalid query parameter: $key');
      }
      argsHost.query[key] = doubleValue;
    }
  }
}

/// Represents an integer parsing pipe.
class ParseIntPipe extends Pipe {
  /// The key to look for in the request.
  final String key;

  /// The binding type of the pipe.
  final PipeBindingType bindingType;

  /// Function to handle errors during parsing.
  final SerinusException Function(String key)? onError;

  /// Creates a new instance of [ParseIntPipe].
  ParseIntPipe(this.key, {required this.bindingType, this.onError});

  @override
  Future<void> transform(ExecutionContext context) async {
    final argsHost = context.argumentsHost;
    if (argsHost is! HttpArgumentsHost) {
      return;
    }
    if (bindingType == PipeBindingType.params) {
      final value = int.tryParse(argsHost.params[key] ?? '');
      if (value == null) {
        throw onError?.call(key) ??
            BadRequestException('Invalid parameter: $key');
      }
      argsHost.params[key] = value;
    }
    if (bindingType == PipeBindingType.query) {
      final intValue = int.tryParse(argsHost.query[key]?.toString() ?? '');
      if (intValue == null) {
        throw onError?.call(key) ??
            BadRequestException('Invalid query parameter: $key');
      }
      argsHost.query[key] = intValue;
    }
  }
}

/// Represents a boolean parsing pipe.
class ParseBoolPipe extends Pipe {
  /// The key to look for in the request.
  final String key;

  /// The binding type of the pipe.
  final PipeBindingType bindingType;

  /// Function to handle errors during parsing.
  final SerinusException Function(String key)? onError;

  /// Creates a new instance of [ParseBoolPipe].
  ParseBoolPipe(this.key, {required this.bindingType, this.onError});

  @override
  Future<void> transform(ExecutionContext context) async {
    final argsHost = context.argumentsHost;
    if (argsHost is! HttpArgumentsHost) {
      return;
    }
    if (bindingType == PipeBindingType.params) {
      final boolValue =
          argsHost.params[key]?.toString().toLowerCase() == 'true';
      argsHost.params[key] = boolValue;
    }
    if (bindingType == PipeBindingType.query) {
      final boolValue = argsHost.query[key]?.toString().toLowerCase() == 'true';
      argsHost.query[key] = boolValue;
    }
  }
}

/// Represents a default value pipe.
class DefaultValuePipe<T> extends Pipe {
  /// The default value to be set if the key is not present in the request.
  final T value;

  /// The key to look for in the request.
  final String key;

  /// The binding type of the pipe.
  final PipeBindingType bindingType;

  /// Creates a new instance of [DefaultValuePipe].
  DefaultValuePipe(this.value, {required this.key, required this.bindingType}) {
    if (bindingType == PipeBindingType.params) {
      throw ArgumentError(
        'Params binding type cannot be used with DefaultValuePipe.',
      );
    }
  }

  @override
  Future<void> transform(ExecutionContext context) async {
    final argsHost = context.argumentsHost;
    if (argsHost is! HttpArgumentsHost) {
      return;
    }
    argsHost.query[key] ??= value;
  }
}

/// Represents a transformation pipe.
///
/// This pipe is responsible for transforming the request context.
class TransformPipe<R> extends Pipe {
  /// The transformer function is responsible for transforming the request context.
  final Future<R> Function(ExecutionContext context) transformer;

  /// Creates a new instance of [TransformPipe].
  const TransformPipe(this.transformer);

  @override
  Future<void> transform(ExecutionContext context) async {
    try {
      await transformer(context);
    } catch (e) {
      throw BadRequestException('Transform failed: $e');
    }
  }
}
