import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:serinus/serinus.dart';
import 'package:stream_channel/stream_channel.dart';

class SseAdapter extends Adapter<Map<String, dynamic>> {

  Logger logger = Logger('SseAdapter');

  HttpServer? connection;

  final int port;

  bool _isOpen = false;
  
  @override
  bool get isOpen => _isOpen;

  SseAdapter({required this.port});

  @override
  Future<void> init() async {
    server = {};
    connection = await HttpServer.bind(InternetAddress.loopbackIPv4, port, shared: true);
    logger.info('SSE server is running on port $port');
    final serverUri = Uri.parse('http://${connection?.address.host}:${connection?.port}');
    connection?.listen((data) async {
      print(data);
      final streamReq = StreamedRequest(
        data.method,
        serverUri.replace(path: data.uri.path, query: data.uri.query),
      )..followRedirects = false
      ..headers['host'] = serverUri.authority;
      data.headers.forEach((header, value) {
        streamReq.headers[header] = value.join(',');
      });
      streamReq.sink.close();
      print(streamReq.contentLength);
      final streamResp = await Client().send(streamReq);
      final initChannel = await _initializeChannel(data);

      StreamSubscription? serverSeeSub;
      StreamSubscription? reqChannelSub;

      serverSeeSub = utf8.decoder.bind(streamResp.stream).listen(initChannel.sink.add, onDone: () {
        reqChannelSub?.cancel();
        initChannel.sink.close();
      });

      reqChannelSub = initChannel.channel.stream.listen((_) {}, onDone: () {
        serverSeeSub?.cancel();
        initChannel.sink.close();
      });

    });
    _isOpen = true;
  }

  Future<({StreamChannel channel, StringConversionSink sink})> _initializeChannel(HttpRequest req) async {
    final socket = await req.response.detachSocket();
    final channel = StreamChannel<List<int>>(socket, socket);
    final sink = utf8.encoder.startChunkedConversion(channel.sink)
      ..add('HTTP/1.1 200 OK\r\n'
          'Content-Type: text/event-stream\r\n'
          'Cache-Control: no-cache\r\n'
          'Connection: keep-alive\r\n'
          'Access-Control-Allow-Credentials: true\r\n'
          'Access-Control-Allow-Origin: ${req.headers['origin']}\r\n'
          '\r\n');
    return (
      channel: channel,
      sink: sink
    );
  }

  @override
  Future<void> close() async {
    if (server == null) {
      return;
    }
    connection?.close(force: true);
    _isOpen = false;
  }

  @override
  Future<void> listen(RequestCallback requestCallback,
      {dynamic request, ErrorHandler? errorHandler}) async {
      return;
  }
  
  @override
  bool get shouldBeInitilized => true;

  @override
  bool canHandle(InternalRequest request) {
    return request.headers['accept'] == 'text/event-stream' && request.method == 'GET';
  }

}