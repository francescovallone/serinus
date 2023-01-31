import 'dart:convert';
import 'dart:io';

import 'package:mug/mug.dart';
import 'package:test/test.dart';

void main() {
  test('should create and serve a minimal web app', () async {
    final mug = MugFactory.createApp(AppModule(), developmentMode: false);
    await mug.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://127.0.0.1:3000/"));
    final response = await request.close();
    expect(response.statusCode, equals(HttpStatus.ok));
    await mug.close();
  });

  test('should return 404 if route doesn\'t exist', () async {
    final mug = MugFactory.createApp(AppModule(), developmentMode: false, port: 3001);
    await mug.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3001/tt"));
    final response = await request.close();
    expect(response.statusCode, equals(HttpStatus.notFound));
    await mug.close();
  });

  test('should get "Pong!"', () async {
    final mug = MugFactory.createApp(AppModule(), developmentMode: false, port: 3002);
    await mug.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3002/"));
    final response = await request.close();
    response.listen((event) {
      String text = Utf8Decoder().convert(event).replaceAll("\"", "");
      expect(text, equals("Pong!"));
    });
    await mug.close();
  });

  test('should get "Pong! 1"', () async {
    final mug = MugFactory.createApp(AppModule(), developmentMode: false, port: 3003);
    await mug.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3003/test/1"));
    final response = await request.close();
    response.listen((event) {
      String text = Utf8Decoder().convert(event).replaceAll("\"", "");
      expect(text, equals("Pong! 1"));
    });
    await mug.close();
  });

  test('should get 400 on status code"', () async {
    final mug = MugFactory.createApp(AppModule(), developmentMode: false, port: 3003);
    await mug.serve();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse("http://localhost:3003/test/dsa"));
    final response = await request.close();
    expect(response.statusCode, equals(HttpStatus.badRequest));
    await mug.close();
  });
}


class AppModule implements Module{
  AppModule();
  
  @override
  List<dynamic> controllers = [AppController()];
  
  @override
  List? imports = [];
}

@Controller(
  path: ""
)
class AppController{
  const AppController();

  @Route("/", method: "GET")
  String ping(){
    return "Pong!";
  }

  @Route("/test/:id", method: "GET")
  String param(@Param('id') int id){
    return "Pong! $id";
  }
  
}