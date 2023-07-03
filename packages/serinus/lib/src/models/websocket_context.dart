import 'dart:async';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/decorators/http/websocket/web_socket_gateway.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketContext{

  final WebSocketGateway gateway;
  final Type type;
  List<WebSocketChannel> channels = [];
  StreamController<dynamic> _controller = StreamController<dynamic>();

  WebSocketContext({
    required this.gateway,
    required this.type,
  });

  Future<void> connect(Request request) async {
    Socket socket = await request.httpRequest.response.detachSocket(writeHeaders: false);
    WebSocketChannel channel = request.upgradeToWebSocket(
      socket
    );
    this.channels.add(channel);
    channel.stream.listen((event) {
      _controller.add(event);
    });
  }

  void onConnection(){}

  Future<void> emit<T>(T message) async{
    if(channels.isNotEmpty){
      await Future.microtask((){
        channels.forEach((element) { 
          element.sink.add(message);
        });
      });
    }
  }

  void listen<T>(Function(T) callback){
    _controller.stream.listen((event){
      callback(event);
    });
  }

  Future<void> close() async{
    if(channels.isNotEmpty){
      await Future.microtask((){
        channels.forEach((element) { 
          element.sink.close();
        });
        channels.clear();
      });
    }
  }

}