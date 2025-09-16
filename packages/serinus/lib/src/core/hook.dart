import '../contexts/contexts.dart';
import '../utils/wrapped_response.dart';

/// The [Hook] class is used to create hooks that can be used to execute code before and after the request is handled
abstract class Hook extends Processable implements Hookable {
  /// The [Hook] constructor is used to create a [Hook] object.
  const Hook();

  /// The Hook can expose a service that will be used by the application without the need to create a new module.
  ///
  /// The service can be accessed by the [RequestContext] object and they are treated as global services.
  Object? get service => null;
}

/// The [Hookable] class is used to create a hookable object.
abstract class Hookable {}

/// The [Processable] class is used to create a processable object.
abstract class Processable {
  /// The [Processable] constructor is used to create a [Processable] object.
  const Processable();
}

/// The [OnRequest] mixin is used to execute code before and after the request is handled
mixin OnRequest on Hook {
  /// The [onRequest] method is used to execute code before the request is handled
  Future<void> onRequest(ExecutionContext context);
}

/// The [OnResponse] mixin is used to execute code before the response is sent
mixin OnResponse on Hook {
  /// The [onResponse] method is used to execute code before the response is sent
  Future<void> onResponse(ExecutionContext context, WrappedResponse data);
}

/// The [OnBeforeHandle] mixin is used to execute code before the request is handled
mixin OnBeforeHandle on Hookable {
  /// The [beforeHandle] method is used to execute code before the request is handled
  Future<void> beforeHandle(ExecutionContext context);
}

/// The [OnAfterHandle] mixin is used to execute code after the request is handled
mixin OnAfterHandle on Hookable {
  /// The [afterHandle] method is used to execute code after the request is handled
  Future<void> afterHandle(ExecutionContext context, WrappedResponse response);
}

/// The [OnException] mixin is used to execute code when an exception is thrown
mixin OnException on Hook {
  /// The [exceptionTypes] property contains the types of exceptions that this hook can handle
  /// This is used to filter the exceptions that this hook will handle.
  List<Type> get exceptionTypes;

  /// The [onException] method is used to execute code when an exception is thrown
  Future<void> onException(
    ExecutionContext request,
    Exception exception,
  ) async {}
}
