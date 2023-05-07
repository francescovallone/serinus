import 'dart:async';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/models/models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketContext{

  final WebSocketGateway gateway;
  final List<EventContext> events;
  final Type type;
  List<WebSocketChannel> channels = [];


  WebSocketContext({
    required this.gateway,
    required this.events,
    required this.type,
  });


  Future<void> initialize(Request request) async {
    Socket socket = await request.httpRequest.response.detachSocket(writeHeaders: false);
    this.channels.add(request.upgradeToWebSocket(
      socket
    ));
  }

  Future<void> emit(dynamic message) async{
    if(channels.isNotEmpty){
      await Future.microtask((){
        channels.forEach((element) { 
          element.sink.add(message);
        });
      });
    }
  }

  void listen(Function(dynamic) callback){
    if(channels.isNotEmpty){
      channels.forEach((element) { 
        element.stream.asBroadcastStream().listen(
          callback,
        );
      });
    }
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