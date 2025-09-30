import '../core/core.dart';
import '../http/http.dart';
import 'contexts.dart';

/// The [SseContext] class is used to store the context of a Server-Sent Event (SSE).
class SseContext extends RequestContext<dynamic> {
  /// The [clientId] is used to uniquely identify the client.
  final String clientId;

  /// Creates a new instance of [SseContext].
  SseContext(
    Request httpRequest,
    Map<Type, Provider> providers,
    Map<Type, Object> hooksServices,
    this.clientId,
  ) : super.withBody(httpRequest, httpRequest.body, providers, hooksServices);
}
