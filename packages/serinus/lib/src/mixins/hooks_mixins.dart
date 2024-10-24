import '../contexts/contexts.dart';
import '../core/core.dart';
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
mixin OnBeforeHandle on Hook, Route {
  /// The [beforeHandle] method is used to execute code before the request is handled
  Future<void> beforeHandle(RequestContext context) async {}
}

/// The [OnAfterHandle] mixin is used to execute code after the request is handled
mixin OnAfterHandle on Hook, Route {
  /// The [afterHandle] method is used to execute code after the request is handled
  Future<void> afterHandle(RequestContext context, dynamic response) async {}
}

/// The [OnTransform] mixin is used to execute code before the request is handled
mixin OnTransform on Route {
  /// The [transform] method is used to execute code before the request is handled
  Future<void> transform(RequestContext context) async {}
}
