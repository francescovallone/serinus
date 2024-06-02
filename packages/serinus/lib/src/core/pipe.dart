import '../contexts/execution_context.dart';

/// The [Pipe] class is used to define a pipe.
abstract class Pipe {
  /// The [transform] method is used to transform the context.
  Future<void> transform(ExecutionContext context);
}
