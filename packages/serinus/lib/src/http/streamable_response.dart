import 'dart:io';

import 'http.dart';


class StreamableResponse {

  final InternalResponse _response;

  bool _initialized = false;

  StreamableResponse(this._response);

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

  void send(String data) {
    _response.write('data: $data\n\n');
  }

  Response end() {
    return Response.closeStream();
  }

}

final class StreamedResponse {}