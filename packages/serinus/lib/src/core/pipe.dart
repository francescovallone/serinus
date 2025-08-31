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

  final SerinusException Function(String key, ValidationError error)? onError;

  /// Creates a new instance of [BodySchemaValidationPipe].
  const BodySchemaValidationPipe(this.schema, {this.onError});

  @override
  Future<void> transform(ExecutionContext context) async {
    try {
      if(context.hostType != HostType.http) {
        return;
      }
      final reqContext = context.switchToHttp();
      final result = schema.parse(context.body.value);
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
      throw onError?.call(e.key, e) ?? BadRequestException('Body validation failed: $e');
    }
  }
}

enum PipeBindingType {
  query,
  params,
}

class ParseDatePipe extends Pipe {

  final String key;

  final PipeBindingType bindingType;

  final SerinusException Function(String key)? onError;

  ParseDatePipe(
    this.key,
    {
      required this.bindingType,
      this.onError,
    }
  );

  @override
  Future<void> transform(ExecutionContext context) async {
    if (bindingType == PipeBindingType.params) {
      final dateValue = DateTime.tryParse(context.params[key] ?? '');
      if (dateValue == null) {
        throw onError?.call(key) ?? BadRequestException('Invalid parameter: $key');
      }
      context.params[key] = dateValue;
    }
    if (bindingType == PipeBindingType.query) {
      final dateValue = DateTime.tryParse(context.query[key]?.toString() ?? '');
      if (dateValue == null) {
        throw onError?.call(key) ?? BadRequestException('Invalid query parameter: $key');
      }
      context.query[key] = dateValue;
    }
  }

}

class ParseDoublePipe extends Pipe {

  final String key;

  final PipeBindingType bindingType;

  final SerinusException Function(String key)? onError;

  ParseDoublePipe(
    this.key,
    {
      required this.bindingType,
      this.onError,
    }
  );

  @override
  Future<void> transform(ExecutionContext context) async {
    if (bindingType == PipeBindingType.params) {
      final doubleValue = double.tryParse(context.params[key] ?? '');
      if (doubleValue == null) {
        throw onError?.call(key) ?? BadRequestException('Invalid parameter: $key');
      }
      context.params[key] = doubleValue;
    }
    if (bindingType == PipeBindingType.query) {
      final doubleValue = double.tryParse(context.query[key]?.toString() ?? '');
      if (doubleValue == null) {
        throw onError?.call(key) ?? BadRequestException('Invalid query parameter: $key');
      }
      context.query[key] = doubleValue;
    }
  }

}


class ParseIntPipe extends Pipe {

  final String key;

  final PipeBindingType bindingType;

  final SerinusException Function(String key)? onError;

  ParseIntPipe(
    this.key,
    {
      required this.bindingType,
      this.onError,
    }
  );

  @override
  Future<void> transform(ExecutionContext context) async {
    if (bindingType == PipeBindingType.params) {
      final value = int.tryParse(context.params[key] ?? '');
      if (value == null) {
        throw onError?.call(key) ?? BadRequestException('Invalid parameter: $key');
      }
      context.params[key] = value;
    }
    if (bindingType == PipeBindingType.query) {
      final intValue = int.tryParse(context.query[key]?.toString() ?? '');
      if (intValue == null) {
        throw onError?.call(key) ?? BadRequestException('Invalid query parameter: $key');
      }
      context.query[key] = intValue;
    }
    
  }

}

class ParseBoolPipe extends Pipe {

  final String key;

  final PipeBindingType bindingType;

  final SerinusException Function(String key)? onError;

  ParseBoolPipe(
    this.key,
    {
      required this.bindingType,
      this.onError,
    }
  );

  @override
  Future<void> transform(ExecutionContext context) async {
    if (bindingType == PipeBindingType.params) {
      final boolValue = context.params[key]?.toString().toLowerCase() == 'true';
      context.params[key] = boolValue;
    }
    if (bindingType == PipeBindingType.query) {
      final boolValue = context.query[key]?.toString().toLowerCase() == 'true';
      context.query[key] = boolValue;
    }
  }

}

class DefaultValuePipe<T> extends Pipe {

  final T value;

  final String key;

  final PipeBindingType bindingType;

  DefaultValuePipe(
    this.value,
    {
      required this.key,
      required this.bindingType,
    }
  ) {
    if (bindingType == PipeBindingType.params) {
      throw ArgumentError('Params binding type cannot be used with DefaultValuePipe.');
    }
  }

  @override
  Future<void> transform(ExecutionContext context) async {
    context.query[key] ??= value;
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
