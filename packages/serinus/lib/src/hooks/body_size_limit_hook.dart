import '../../serinus.dart';

/// The [BodySizeLimitHook] class is used to define a body size limit hook.
class BodySizeLimitHook extends Hook {

  /// The maximum size of the body in bytes.
  final int maxSize;

  /// The [BodySizeLimitHook] constructor is used to create a new instance of the [BodySizeLimitHook] class.
  const BodySizeLimitHook({this.maxSize = 1024 * 1024});

  @override
  Future<void> onRequest(Request request, InternalResponse response) async {
    await request.parseBody();
    if (request.contentLength > maxSize) {
      throw PayloadTooLargeException(
        message: 'Request body size is too large',
        uri: Uri(path: request.path),
      );
    }
  }

}