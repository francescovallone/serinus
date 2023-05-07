import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:serinus/serinus.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// The class Request is used to handle the request
/// it also contains the [httpRequest] property that contains the [HttpRequest] object from dart:io
class Request{

  /// The [path] property contains the path of the request
  late String path;
  /// The [uri] property contains the uri of the request
  late Uri uri;
  /// The [method] property contains the method of the request
  late String method;
  /// The [segments] property contains the segments of the request
  late List<String> segments;
  /// The [httpRequest] property contains the [HttpRequest] object from dart:io
  late HttpRequest _httpRequest;
  /// The [headers] property contains the headers of the request
  Map<String, dynamic> headers = {};
  /// The [bytes] property contains the bytes of the request body
  Uint8List? _bytes;
  /// The [queryParameters] property contains the query parameters of the request
  late Map<String, String> queryParameters;
  /// The [contentType] property contains the content type of the request
  ContentType contentType = ContentType('text', 'plain');
  HttpRequest get httpRequest => _httpRequest;

  String webSocketKey = "";

  /// The [Request.fromHttpRequest] constructor is used to create a [Request] object from a [HttpRequest] object
  Request.fromHttpRequest(HttpRequest request){
    path = request.requestedUri.path;
    uri = request.requestedUri;
    method = request.method;
    queryParameters = request.requestedUri.queryParameters;
    segments = Uri(path: request.requestedUri.path).pathSegments;
    contentType = request.headers.contentType ?? ContentType('text', 'plain');
    _httpRequest = request;
    _httpRequest.headers.forEach((name, values) {
      headers[name] = values.join(';');
    });
    headers.remove(HttpHeaders.transferEncodingHeader);
  }

  /// This method is used to get the body of the request as a [String]
  /// 
  /// Example:
  /// ``` dart
  /// String body = await request.body();
  /// ```
  Future<String> body() async {
    final data = await bytes();
    if(data.isEmpty){
      return "";
    }
    String stringData = utf8.decode(data);
    return stringData;
  }

  /// This method is used to get the body of the request as a [dynamic] json object
  /// 
  /// Example:
  /// ``` dart
  /// dynamic json = await request.json();
  /// ```
  Future<dynamic> json() async {
    final data = await body();
    if(data.isEmpty){
      return {};
    }
    try{
      dynamic jsonData = jsonDecode(data);
      contentType = ContentType('application', 'json');
      return jsonData;
    }catch(e){
      throw BadRequestException(message: "The json body is malformed");
    }
  }

  /// This method is used to get the body of the request as a [Uint8List]
  /// it is used internally by the [body], the [json] and the [stream] methods
  Future<Uint8List> bytes() async {
    try{
      if(_bytes == null){
        _bytes = await _httpRequest.firstWhere((element) => element.isNotEmpty);
      }
      return _bytes!;
    }catch(_){
      return Uint8List(0);
    }
  }

  /// This method is used to get the body of the request as a [Stream<List<int>>]
  Future<Stream<List<int>>> stream() async {
    try{
      await bytes();
      return Stream.value(
        List<int>.from(_bytes!)
      );
    }catch(_){
      return Stream.value(
        List<int>.from(Uint8List(0))
      );
    }
  }

  bool get isWebSocket {
    if(method != "GET"){
      return false;
    }
    final connection = httpRequest.headers.value('Connection');
    if(connection == null){
      return false;
    }
    final tokens = connection.toLowerCase().split(',').map((token) => token.trim());
    if(!tokens.contains('upgrade')){
      return false;
    }
    final upgrade = httpRequest.headers.value('Upgrade');
    if(upgrade == null){
      return false;
    }
    if(upgrade.toLowerCase() != 'websocket'){
      return false;
    }

    final version = httpRequest.headers.value('Sec-WebSocket-Version');
    if(version == null){
      throw BadRequestException(message: 'missing Sec-WebSocket-Version header.');
    }else if(version != '13'){
      return false;
    }

    if(httpRequest.protocolVersion != '1.1'){
      throw BadRequestException(message: 'unexpected HTTP version "${httpRequest.protocolVersion}".');
    }

    final key = httpRequest.headers.value('Sec-WebSocket-Key');
    
    if(key == null){
      throw BadRequestException(message: 'missing Sec-WebSocket-Key header.');
    }

    webSocketKey = key;

    final origin = httpRequest.headers.value('Origin');

    return true;
  }

  WebSocketChannel upgradeToWebSocket(Socket socket) {
    final channel = StreamChannel<List<int>>(socket, socket);
    final sink = utf8.encoder.startChunkedConversion(channel.sink)
      ..add('HTTP/1.1 101 Switching Protocols\r\n'
          'Upgrade: websocket\r\n'
          'Connection: Upgrade\r\n'
          'Sec-WebSocket-Accept: ${WebSocketChannel.signKey(webSocketKey)}\r\n');
    sink.add('\r\n');
    // ignore: avoid_dynamic_calls
    return WebSocketChannel(channel);
  }


}