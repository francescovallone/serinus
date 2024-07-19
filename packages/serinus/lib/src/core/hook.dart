import '../../serinus.dart';

/// The [Hook] class is used to create hooks that can be used to execute code before and after the request is handled
abstract class Hook {
  /// The [Hook] constructor is used to create a [Hook] object.
  const Hook();

  /// The [onRequest] method is used to execute code before the request goes through the handling process
  Future<void> onRequest(Request request, InternalResponse response) async {}

  /// The [beforeHandle] method is used to execute code before the request is handled
  Future<void> beforeHandle(RequestContext context) async {}

  /// The [afterHandle] method is used to execute code after the request is handled
  Future<void> afterHandle(RequestContext context, Response response) async {}

  /// The [onResponse] method is used to execute code after the response is sent
  Future<void> onResponse(dynamic data, ResponseProperties properties) async {}
}
