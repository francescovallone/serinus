import 'dart:io';

import 'http.dart';

/// The [StreamableResponse] class is used to create a streamable response.
/// 
/// It is used to send data to the client in a streamable way.
class StreamableResponse {

  final InternalResponse _response;

  bool _initialized = false;

  /// The [StreamableResponse] constructor is used to create a new instance of the [StreamableResponse] class.
  StreamableResponse(this._response);

  /// This method is used to initialize the response.
  /// 
  /// It is called when the request context is created.
  /// Any further call to this method will be ignored.
  void init() {
    if(_initialized) {
      return;
    }
    _response.currentHeaders.chunkedTransferEncoding = true;
    _response.contentType(ContentType('text', 'event-stream'));
    _response.headers({
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    });
    _initialized = true;
  }

  /// This method is used to send data to the response.
  void send(Object data) {
    _response.write(data.toString());
  }

  /// This method is used to end the response.
  StreamedResponse end() {
    return StreamedResponse();
  }

}

/// The [StreamedResponse] class is used to notify the server that the response is streamed.
final class StreamedResponse {}