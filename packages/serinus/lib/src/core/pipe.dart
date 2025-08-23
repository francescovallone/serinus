import 'package:acanthis/acanthis.dart';

import '../../serinus.dart';

abstract class Pipe extends Processable {
  /// The [Pipe] constructor is used to create a [Pipe] object.
  const Pipe();
  /// Transform and validate the input data
  Future<void> transform(RequestContext context);
}

class BodySchemaValidationPipe<T extends Body> extends Pipe {
  final AcanthisType schema;
  
  const BodySchemaValidationPipe(this.schema);
  
  @override
  Future<void> transform(RequestContext context) async {
    try {
      final result = schema.tryParse(context.body.value);
      switch (schema) {
        case AcanthisMap():
          context.body = JsonBody.fromJson(result.value as Map<String, dynamic>);
          break;
        case AcanthisList():
          context.body = JsonBody.fromJson(result.value as List<dynamic>);
          break;
        case AcanthisType():
          context.body = TextBody(result.value.toString());
      }
    } catch(e) {
      throw BadRequestException('Body validation failed: $e');
    }
  }
}

class TransformPipe<R> extends Pipe {
  final Future<R> Function(RequestContext context) transformer;
  
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