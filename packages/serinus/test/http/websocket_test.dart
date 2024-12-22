import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class TestRoute extends Route {
  const TestRoute({
    required super.path,
    super.method = HttpMethod.get,
  });
}

class TestJsonObject with JsonObject {
  @override
  Map<String, dynamic> toJson() {
    return {'id': 'json-obj'};
  }
}

class TestModule extends Module {
  TestModule(
      {super.controllers, super.imports, super.providers, super.exports});
}

class WsGateway extends WebSocketGateway {
  WsGateway({super.path});

  @override
  Future<void> onMessage(dynamic data, WebSocketContext context) async {
    context.send(data);
  }
}

class WsGatewayMixins extends WebSocketGateway
    with OnClientConnect, OnClientDisconnect {
  bool onClientConnectCalled = false;
  bool onClientDisconnectCalled = false;

  WsGatewayMixins({super.path});

  @override
  Future<void> onMessage(dynamic data, WebSocketContext context) async {
    context.send(data);
  }

  @override
  Future<void> onClientConnect(String clientId) async {
    onClientConnectCalled = true;
  }

  @override
  Future<void> onClientDisconnect(String clientId) async {
    onClientDisconnectCalled = true;
  }
}

void main() {
  group('$WebSocket', () {
    test(
        'when a module import the WsModule and use a WebSocketGateway it should possible to connect using a websocket',
        () async {
      final app = await serinus.createApplication(
          entrypoint:
              TestModule(imports: [WsModule()], providers: [WsGateway()]),
          logLevels: [LogLevel.none],
          port: 3004);
      await app.serve();
      final ws = await WebSocket.connect('ws://localhost:3004/');
      ws.add('Hello from client');
      final message = await ws.first;
      expect(message, 'Hello from client');
      await app.close();
    });

    test(
      'when a module import the WsModule and use a WebSocketGateway and the path param is not null then the gateway should only accept connections on the specified path',
      () async {
        final app = await serinus.createApplication(
            entrypoint: TestModule(
                imports: [WsModule()], providers: [WsGateway(path: '/ws')]),
            logLevels: [LogLevel.none],
            port: 3001);
        await app.serve();
        try {
          await WebSocket.connect('ws://localhost:3001/');
        } catch (e) {
          expect(e, isA<WebSocketException>());
        }
        final ws = await WebSocket.connect('ws://localhost:3001/ws');
        ws.add('Hello from client');
        final message = await ws.first;
        expect(message, 'Hello from client');
      },
    );

    test(
      'when a module import the WsModule and use a WebSocketGateway and the path param is not null then the gateway should only accept connections on the specified path',
      () async {
        final gateway = WsGatewayMixins(path: '/ws');
        final app = await serinus.createApplication(
            entrypoint: TestModule(imports: [WsModule()], providers: [gateway]),
            logLevels: [LogLevel.none],
            port: 3002);
        await app.serve();
        final ws = await WebSocket.connect('ws://localhost:3002/ws');
        ws.add('Hello from client');
        final message = await ws.first;
        expect(message, 'Hello from client');
        await ws.close();
        await app.close();
        expect(gateway.onClientConnectCalled, true);
        expect(gateway.onClientDisconnectCalled, true);
      },
    );
  });
}
