import 'contexts.dart';

/// The [SseContext] class is used to store the context of a Server-Sent Event (SSE).
class SseContext extends RequestContext {

  /// The [clientId] is used to uniquely identify the client.
  final String clientId;

  /// Creates a new instance of [SseContext].
  SseContext(super.request, super.providers, super.hooksServices, this.clientId);

}
