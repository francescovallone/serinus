---
title: Serinus - The modular Backend for your Flutter apps
titleTemplate: false
layout: page
sidebar: false

head:
  - - meta
    - property: 'og:title'
      content: Serinus - The modular Backend for your Flutter apps
  - - meta
    - name: 'description'
      content: Serinus is an open-source framework for building efficient and scalable backend applications powered by Dart.
  - - meta
    - property: 'og:description'
      content: Serinus is an open-source framework for building efficient and scalable backend applications powered by Dart.
  - - meta
    - property: 'og:image'
      content: https://serinus.app/serinus.webp
  - - meta
    - property: 'twitter:card'
      content: 'https://serinus.app/cover.jpg'
  - - meta
    - name: 'twitter:image'
      content: 'https://serinus.app/cover.jpg'
---

<script setup>
  import Home from './components/home/home.vue';
</script>

<Home>
  <template #start>

:::code-group

```dart canary [Entrypoint]
import 'package:serinus/serinus.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
  );
  await app.serve();
}
```

```dart canary [Module]
import 'package:serinus/serinus.dart';

import 'app_controller.dart';

class AppModule extends Module {
  AppModule() : super(
    controllers: [AppController()],
  );
}
```

```dart canary [Controller]
import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController() : super('/') {
    on(Route.get('/'), _handleHelloWorld);
  }

  String _handleHelloWorld(RequestContext context) {
    return 'Hello, World!';
  }
}
```

:::

  </template>
  <template #configuration>

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_config/serinus_config.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [
      ConfigModule()
    ],
  );
}
```

  </template>
  <template #cron_jobs>

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_schedule/serinus_schedule.dart';

class AppProvider extends Provider with OnApplicationBootstrap {
  final ScheduleRegistry registry;

  @override
  Future<void> onApplicationBootstrap() async {
    registry.addCronJob(
      'hello',
      '*/5 * * * *',
      () async {
        print('Hello world');
      }
    );
  }
}
```

  </template>
  <template #authentication>

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/serinus_frontier.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [
        FrontierModule([
          JwtStrategy(
            JwtStrategyOptions(
              SecretKey('default_secret'), 
              jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken()
            ),
            (options, jwt, done) async {
              final decodedJwt = jwt as JWT;
              return done(decodedJwt.payload);
            }
          )
        ]);
    ]);
}
```

  </template>
  <template #openapi>

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [
      OpenApiModule.v3(
        InfoObject(
          title: 'My API',
          version: '1.0.0',
          description: 'This is my API',
        ),
        analyze: true,
      ),
    ]
  );
}
```

  </template>
  <template #websockets>
  
```dart
import 'package:serinus/serinus.dart';

class ChatGateway extends WebSocketGateway {
  @override
  Future<void> onMessage(dynamic data, WebSocketContext context) async {
    context.sendText('Message received: $data');
  }
}
```

  </template>
  <template #testing>

```dart
import 'package:serinus_test/serinus_test.dart';
import 'package:serinus/serinus.dart';

void main() {
  test('Test provider', () async {
    final application = await serinus.createTestApplication(
      entrypoint: AppModule(),
      host: InternetAddress.anyIPv4.address,
      port: 3002,
      logger: ConsoleLogger(
        prefix: 'Serinus New Logger',
        
      ),
    );
    await application.serve();
    final res = await application.get('/provider');
    expect(res.body, 'Hello from TestProvider');
  });
}
```

  </template>
</Home>
