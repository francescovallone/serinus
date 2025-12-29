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

```dart [Entrypoint]
import 'package:serinus/serinus.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
  );
  await app.serve();
}
```

```dart [Module]
import 'package:serinus/serinus.dart';

import 'app_controller.dart';

class AppModule extends Module {
  AppModule() : super(
    controllers: [AppController()],
  );
}
```

```dart [Controller]
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

### Configuration

<p><span class="numbered">1</span>Import the configuration module</p>

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_config/serinus_config.dart';

class AppModule extends Module {

  AppModule() : super(
    imports: [ConfigModule()],
    controllers: [AppController()],
  );

}
```

<p><span class="numbered">2</span>Use the ConfigService to access environment variables</p>

```dart
class AppController extends Controller {
  final Config config;

  AppController(this.config) : super('/') {
    on(Route.get('/'), _handleHelloWorld);
  }

  String _handleHelloWorld(RequestContext context) {
    final configService = context.use<ConfigService>();
    final myEnvVar = configService.getOrThrow('TEST');
    return 'My env var is: $myEnvVar';
  }
}
```

  </template>
  <template #cron_jobs>

### Scheduled Tasks

<p><span class="numbered">1</span>Import the module</p>
  
```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_schedule/serinus_schedule.dart';

class AppModule extends Module {

  AppModule(): super(
    imports: [
      ScheduleModule()
    ],
    controllers: [
      AppController()
    ],
  )

}
```

<p><span class="numbered">2</span>Use the ScheduleRegistry to register a cron job</p>

```dart
class AppController extends Controller {

  AppController(): super('/') {
    on(Route.get('/'), (RequestContext context) {
      final registry = context.use<ScheduleRegistry>();
      registry.addCronJob(
        'hello',
        '*/5 * * * *',
        () async {
          print('Hello world');
        }
      );
    });
  }

}
```

  </template>
  <template #authentication>

### Authentication

<p><span class="numbered">1</span>Import the module and define your strategies</p>

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/serinus_frontier.dart';

class AppModule extends Module {

  AppModule() : super(
    imports: [
        FrontierModule([
            MyStrategy(
                MyStrategyOptions(),
                (options, value, done) => done(value)
            )
        ])
    ]);

}
```

<p><span class="numbered">2</span>Use the GuardMeta to protect your routes</p>

```dart
class MyController extends Controller {

  MyController({super.path = '/'}) {
    on(
        Route.get(
            '/',
            metadata: [
                // MyStrategy is the name of the strategy
                GuardMeta('MyStrategy')
            ]
        ),
        (context) => 'Hello World!'
    );
  }

}
```

  </template>
  <template #openapi>
  
### OpenAPI

Serinus' support for OpenAPI is unique in the Dart landscape. Powerful and gain access to all your routes information with just a module.

<p><span class="numbered">1</span>Import the OpenAPI module</p>

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

<p><span class="numbered">2</span> Access your API spec at http://[your-address]:[port]/api</p>

  </template>
  <template #websockets>

### WebSockets

<p><span class="numbered">1</span>Create a WebSocket gateway</p>
  
```dart
import 'package:serinus/serinus.dart';

class MyGateway extends WebSocketGateway {

  @override
  Future<void> onMessage(dynamic data, WebSocketContext context) async {
    print('Message received: $data');
    context.sendText('Message received: $data');
  }

}
```

<p><span class="numbered">2</span>Register the gateway in a module and import the WsModule</p>

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_websocket/serinus_websocket.dart';

class AppModule extends Module {

  AppModule() : super(
    imports: [
      WsModule()
    ],
    controllers: [
      AppController()
    ],
    providers: [
      MyGateway()
    ]
  );

}
```

  </template>
  <template #testing>

### Testing

<p><span class="numbered">1</span>Create your test case</p>

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
    expect(res.statusCode, 200);
    expect(res.body, 'Hello from TestProvider');
  });
}
```

<p><span class="numbered">2</span>Run your tests</p>

```bash
dart test
```

  </template>
</Home>
