import '../../serinus.dart';
import '../http/internal_request.dart';

/// The [Hook] class is used to create hooks that can be used to execute code before and after the request is handled
abstract class Hook<T> {

  /// The [Hook] constructor is used to create a [Hook] object.
  const Hook();

  /// The [beforeRequest] method is used to execute code before the request is handled
  Future<T?> beforeRequest(Request request, InternalResponse response);

  /// The [onRequest] method is used to execute code after the request is handled
  Future<T?> onRequest(
    Request request,
    RequestContext? context,
    ReqResHandler? handler,
    InternalResponse response,
  ) async {
    return null;
  }

  /// The [afterRequest] method is used to execute code after the response is sent
  Future<void> afterRequest(InternalRequest request, InternalResponse response) async {}

}