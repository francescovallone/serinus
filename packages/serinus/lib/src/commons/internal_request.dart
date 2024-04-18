import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'exceptions/exceptions.dart';
import 'internal_response.dart';


/// The class Request is used to handle the request
/// it also contains the [httpRequest] property that contains the [HttpRequest] object from dart:io

class InternalRequest{

  /// The [path] property contains the path of the request
  final String path;
  /// The [uri] property contains the uri of the request
  final Uri uri;
  /// The [method] property contains the method of the request
  final String method;
  /// The [segments] property contains the segments of the request
  final List<String> segments;
  /// The [original] property contains the [HttpRequest] object from dart:io
  final HttpRequest original;
  /// The [headers] property contains the headers of the request
  final Map<String, dynamic> headers;
  /// The [bytes] property contains the bytes of the request body
  Uint8List? _bytes;
  /// The [queryParameters] property contains the query parameters of the request
  final Map<String, String> queryParameters;
  /// The list of path parameters in the request
  final List<String> pathParameters;
  /// The base url of the server
  final String baseUrl;
  /// The [contentType] property contains the content type of the request
  ContentType contentType;
  /// The [webSocketKey] property contains the key of the web socket
  String webSocketKey = "";

  /// The [Request.from] constructor is used to create a [Request] object from a [HttpRequest] object
  factory InternalRequest.from(HttpRequest request, {String baseUrl = ''}){
    Map<String, String> headers = {};
    request.headers.forEach((name, values) {
      headers[name] = values.join(';');
    });
    headers.remove(HttpHeaders.transferEncodingHeader);
    final segments = Uri(path: request.requestedUri.path).pathSegments;
    final List<String> pathParameters = [];
    for(var i = 1; i < segments.length; i++){
      pathParameters.add(segments[i]);
    }
    return InternalRequest(
      path: request.requestedUri.path,
      uri: request.requestedUri,
      method: request.method,
      segments: segments,
      queryParameters: request.requestedUri.queryParameters,
      headers: headers,
      original: request,
      contentType: request.headers.contentType ?? ContentType('text', 'plain'),
      pathParameters: pathParameters,
      baseUrl: baseUrl
    );
  }

  InternalRequest({
    required this.path,
    required this.uri,
    required this.method,
    required this.segments,
    required this.queryParameters,
    required this.pathParameters,
    required this.headers,
    required this.contentType,
    required this.original,
    required this.baseUrl,
  });

  InternalResponse get response{
    return InternalResponse(original.response, baseUrl: baseUrl);
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
      _bytes ??= await original.firstWhere((element) => element.isNotEmpty);
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

  // bool get isWebSocket {
  //   if(method != "GET"){
  //     return false;
  //   }
  //   final connection = original.headers.value('Connection');
  //   if(connection == null){
  //     return false;
  //   }
  //   final tokens = connection.toLowerCase().split(',').map((token) => token.trim());
  //   if(!tokens.contains('upgrade')){
  //     return false;
  //   }
  //   final upgrade = original.headers.value('Upgrade');
  //   if(upgrade == null){
  //     return false;
  //   }
  //   if(upgrade.toLowerCase() != 'websocket'){
  //     return false;
  //   }

  //   final version = original.headers.value('Sec-WebSocket-Version');
  //   if(version == null){
  //     throw BadRequestException(message: 'missing Sec-WebSocket-Version header.');
  //   }else if(version != '13'){
  //     return false;
  //   }

  //   if(original.protocolVersion != '1.1'){
  //     throw BadRequestException(message: 'unexpected HTTP version "${original.protocolVersion}".');
  //   }

  //   final key = original.headers.value('Sec-WebSocket-Key');
    
  //   if(key == null){
  //     throw BadRequestException(message: 'missing Sec-WebSocket-Key header.');
  //   }

  //   webSocketKey = key;
  //   return true;
  // }

  // WebSocketChannel upgradeToWebSocket(Socket socket) {
  //   final channel = StreamChannel<List<int>>(socket, socket);
  //   final sink = utf8.encoder.startChunkedConversion(channel.sink)
  //     ..add('HTTP/1.1 101 Switching Protocols\r\n'
  //         'Upgrade: websocket\r\n'
  //         'Connection: Upgrade\r\n'
  //         'Sec-WebSocket-Accept: ${WebSocketChannel.signKey(webSocketKey)}\r\n');
  //   sink.add('\r\n');
  //   // ignore: avoid_dynamic_calls
  //   return WebSocketChannel(channel);
  // }


}