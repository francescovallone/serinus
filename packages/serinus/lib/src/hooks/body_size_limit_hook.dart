import '../contexts/contexts.dart';
import '../core/core.dart';
import '../exceptions/exceptions.dart';

/// The [BodySizeLimitHook] class is used to define a body size limit hook.
class BodySizeLimitHook extends Hook with OnRequest {
  /// The maximum size of the body in bytes.
  final int maxSize;

  /// The [BodySizeLimitHook] constructor is used to create a new instance of the [BodySizeLimitHook] class.
  const BodySizeLimitHook({this.maxSize = 1024 * 1024});

  @override
  Future<void> onRequest(ExecutionContext context) async {
    final argsHost = context.argumentsHost;
    if (argsHost is RequestArgumentsHost) {
      final request = argsHost.request;
      await request.parseBody();
      if (request.contentLength > maxSize) {
        throw PayloadTooLargeException(
          'Request body size is too large',
          Uri(path: request.path),
        );
      }
    }
    if (argsHost is RpcArgumentsHost) {
      if ((argsHost.packet.rawPayload?.length ?? 0) > maxSize) {
        throw PayloadTooLargeException('Request body size is too large');
      }
    }
  }
}
