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
  Future<void> transform(RequestContext context);
}

/// Represents a body schema validation pipe.
class BodySchemaValidationPipe<T extends Body> extends Pipe {
  /// The schema to validate against.
  final AcanthisType schema;

  /// Creates a new instance of [BodySchemaValidationPipe].
  const BodySchemaValidationPipe(this.schema);

  @override
  Future<void> transform(RequestContext context) async {
    try {
      final result = schema.tryParse(context.body.value);
      switch (schema) {
        case AcanthisMap():
          context.body = JsonBody.fromJson(
            result.value as Map<String, dynamic>,
          );
          break;
        case AcanthisList():
          context.body = JsonBody.fromJson(result.value as List<dynamic>);
          break;
        case AcanthisType():
          context.body = TextBody(result.value.toString());
      }
    } catch (e) {
      throw BadRequestException('Body validation failed: $e');
    }
  }
}

/// Represents a transformation pipe.
///
/// This pipe is responsible for transforming the request context.
class TransformPipe<R> extends Pipe {
  /// The transformer function is responsible for transforming the request context.
  final Future<R> Function(RequestContext context) transformer;

  /// Creates a new instance of [TransformPipe].
  const TransformPipe(this.transformer);

  @override
  Future<void> transform(RequestContext context) async {
    try {
      await transformer(context);
    } catch (e) {
      throw BadRequestException('Transform failed: $e');
    }
  }
}
