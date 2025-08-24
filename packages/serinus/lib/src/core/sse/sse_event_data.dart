import '../../http/http.dart';

/// Represents the data for a Server-Sent Event (SSE).
class SseEventData {
  /// The incoming HTTP request.
  final IncomingMessage request;

  /// The outgoing HTTP response.
  final OutgoingMessage response;

  /// Creates a new instance of [SseEventData].
  SseEventData({required this.request, required this.response});
}
