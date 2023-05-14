
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

import 'test_module/serinus.dart';

void main() {

  SerinusFactory? serinus;
  setUpAll(() async {
    serinus = Serinus.createApp(forWsTest: true);
  });

  test('should upgrade the request and connect to the websocket', () async {
    serinus?.serve();

    final ws = await WebSocket.connect("ws://localhost:3010");
    final client = HttpClient();
    try{
      var request = await client.getUrl(Uri.parse("http://localhost:3010/"));
      request.close();
      int i = 0;
      await ws.listen((event) {
        if(i == 0){
          expect(event, "ping");
          ws.add("ping");
        }else if(i == 1){
          expect(event, "pong");
          ws.close();
        }
        i++;
      }).asFuture();
    }finally{
      await serinus?.close();
    }
  });
  
}