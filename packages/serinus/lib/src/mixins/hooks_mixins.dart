import '../contexts/contexts.dart';
import '../core/core.dart';
import '../exceptions/exceptions.dart';
import '../http/http.dart';

/// The [OnRequestResponse] mixin is used to execute code before and after the request is handled
mixin OnRequestResponse on Hook {
  /// The [onRequest] method is used to execute code before the request is handled
  Future<void> onRequest(Request request, InternalResponse response) async {}

  /// The [onResponse] method is used to execute code before the response is sent
  Future<void> onResponse(
      Request request, dynamic data, ResponseProperties properties) async {}
}

/// The [OnBeforeHandle] mixin is used to execute code before the request is handled
mixin OnBeforeHandle on Hookable {
  /// The [beforeHandle] method is used to execute code before the request is handled
  Future<void> beforeHandle(RequestContext context);
}

/// The [OnAfterHandle] mixin is used to execute code after the request is handled
mixin OnAfterHandle on Hookable {
  /// The [afterHandle] method is used to execute code after the request is handled
  Future<void> afterHandle(RequestContext context, dynamic response);
}

/// The [OnException] mixin is used to execute code when an exception is thrown
mixin OnException on Hook {
  /// The [onException] method is used to execute code when an exception is thrown
  Future<SerinusException?> onException(RequestContext request, Exception exception) async {
    /// return null If you don't want to transform the exception to be sent to the client
    return null;
  }
}
