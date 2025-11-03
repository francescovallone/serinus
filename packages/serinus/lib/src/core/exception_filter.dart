import '../contexts/contexts.dart';
import 'core.dart';

/// An interface for handling exceptions in the application.
abstract class ExceptionFilter extends Processable {
  /// The list of exception types that this filter can catch.
  final List<Type> catchTargets;

  /// Creates a new instance of [ExceptionFilter].
  const ExceptionFilter({this.catchTargets = const []});

  /// Called when an exception is thrown.
  Future<void> onException(ExecutionContext context, Exception exception);
}
