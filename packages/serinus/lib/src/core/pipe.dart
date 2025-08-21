import '../../serinus.dart';

abstract class Pipe<T, R> extends Processable{
  /// The [Pipe] constructor is used to create a [Pipe] object.
  const Pipe();
  /// Transform and validate the input data
  Future<R> transform(T value, RequestContext context);
}

class BodySchemaValidationPipe<T> extends Pipe<T, T> {
  final ParseSchema schema;
  
  const BodySchemaValidationPipe(this.schema);
  
  @override
  Future<T> transform(T value, RequestContext context) async {
    // Use existing ParseSchema validation logic
    final result = await schema.tryParse(value: value);
    return result['body'] as T;
  }
}

class TransformPipe<T, R> extends Pipe<T, R> {
  final Future<R> Function(T value, RequestContext context) transformer;
  
  const TransformPipe(this.transformer);
  
  @override
  Future<R> transform(T value, RequestContext context) async {
    return await transformer(value, context);
  }
}