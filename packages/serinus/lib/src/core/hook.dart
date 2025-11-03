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

/// A simple hook that executes a function after the request is handled
class AfterHook extends Hook with OnAfterHandle {
  final void Function(ExecutionContext context, WrappedResponse response) _fn;

  /// The [AfterHook] constructor is used to create a new instance of the [AfterHook] class.
  const AfterHook(this._fn);

  @override
  Future<void> afterHandle(
    ExecutionContext context,
    WrappedResponse response,
  ) async {
    _fn(context, response);
  }
}

/// A simple hook that executes a function after the response is sent
class BeforeHook extends Hook with OnBeforeHandle {
  final void Function(ExecutionContext context) _fn;

  /// The [BeforeHook] constructor is used to create a new instance of the [BeforeHook] class.
  const BeforeHook(this._fn);

  @override
  Future<void> beforeHandle(ExecutionContext context) async {
    _fn(context);
  }
}

/// A simple hook that executes a function when the request is received
class RequestHook extends Hook with OnRequest {
  final Future<void> Function(ExecutionContext context) _fn;

  /// The [RequestHook] constructor is used to create a new instance of the [RequestHook] class.
  const RequestHook(this._fn);

  @override
  Future<void> onRequest(ExecutionContext context) async {
    await _fn(context);
  }
}

/// A simple hook that executes a function when the response is sent
class ResponseHook extends Hook with OnResponse {
  final Future<void> Function(ExecutionContext context, WrappedResponse data)
  _fn;

  /// The [ResponseHook] constructor is used to create a new instance of the [ResponseHook] class.
  const ResponseHook(this._fn);

  @override
  Future<void> onResponse(
    ExecutionContext context,
    WrappedResponse data,
  ) async {
    await _fn(context, data);
  }
}
