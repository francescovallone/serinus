import '../contexts/contexts.dart';
import '../core/core.dart';
import '../http/http.dart';
import '../utils/wrapped_response.dart';

/// The [OnRequest] mixin is used to execute code before and after the request is handled
mixin OnRequest on Hook {
  /// The [onRequest] method is used to execute code before the request is handled
  Future<void> onRequest(Request request, ResponseProperties properties) async {}

}

/// The [OnResponse] mixin is used to execute code before the response is sent
mixin OnResponse on Hook {
  /// The [onResponse] method is used to execute code before the response is sent
  Future<void> onResponse(
      Request request, WrappedResponse data, ResponseProperties properties) async {}

}

/// The [OnBeforeHandle] mixin is used to execute code before the request is handled
mixin OnBeforeHandle on Hookable {
  /// The [beforeHandle] method is used to execute code before the request is handled
  Future<void> beforeHandle(RequestContext context);
}

/// The [OnAfterHandle] mixin is used to execute code after the request is handled
mixin OnAfterHandle on Hookable {
  /// The [afterHandle] method is used to execute code after the request is handled
  Future<void> afterHandle(RequestContext context, WrappedResponse response);
}

/// The [OnException] mixin is used to execute code when an exception is thrown
mixin OnException on Hook {
  /// The [onException] method is used to execute code when an exception is thrown
  Future<void> onException(RequestContext request, Exception exception) async {}
}
