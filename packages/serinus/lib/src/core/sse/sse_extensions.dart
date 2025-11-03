import '../../http/http.dart';

/// Extension for [IncomingMessage] to check if it is an SSE request.
extension IsSse on IncomingMessage {
  /// Returns true if the request is an SSE request.
  bool get isSse => headers['accept'] == 'text/event-stream' && method == 'GET';
}
