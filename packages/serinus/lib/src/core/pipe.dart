import '../contexts/execution_context.dart';

abstract class Pipe {
  Future<void> transform(ExecutionContext context);
}
