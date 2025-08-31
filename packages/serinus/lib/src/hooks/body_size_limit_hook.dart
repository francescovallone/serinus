import '../contexts/contexts.dart';
import '../core/core.dart';
import '../exceptions/exceptions.dart';
import '../mixins/mixins.dart';

/// The [BodySizeLimitHook] class is used to define a body size limit hook.
class BodySizeLimitHook extends Hook with OnRequest {
  /// The maximum size of the body in bytes.
  final int maxSize;

  /// The [BodySizeLimitHook] constructor is used to create a new instance of the [BodySizeLimitHook] class.
  const BodySizeLimitHook({this.maxSize = 1024 * 1024});

  @override
  Future<void> onRequest(ExecutionContext context) async {
    final request = context.request;
    await request.parseBody();
    if (request.contentLength > maxSize) {
      throw PayloadTooLargeException(
        'Request body size is too large',
        Uri(path: request.path),
      );
    }
  }
}
