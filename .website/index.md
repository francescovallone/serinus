---
title: Serinus - The backend Flutter deserves
titleTemplate: false
layout: page
sidebar: false

head:
  - - meta
    - property: 'og:title'
      content: Serinus - The backend Flutter deserves
  - - meta
    - name: 'description'
      content: Stop settling for messy backend scripts. Serinus brings enterprise-grade modularity and Dependency Injection to Dart. Clean code, from UI to database.
  - - meta
    - property: 'og:description'
      content: Stop settling for messy backend scripts. Serinus brings enterprise-grade modularity and Dependency Injection to Dart. Clean code, from UI to database.
  - - meta
    - property: 'og:image'
      content: https://serinus.app/cover.jpg
  - - meta
    - property: 'twitter:card'
      content: 'https://serinus.app/cover.jpg'
  - - meta
    - name: 'twitter:image'
      content: 'https://serinus.app/cover.jpg'
---

<script setup>
  import Home from './components/home/home.vue';
  import CodeComparison from './components/code-comparison.vue'
</script>

<Home>
  <template #start>

:::code-group

```dart canary [Entrypoint]
import 'package:serinus/serinus.dart';

import 'app_module.dart';

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

  Future<String> _handleHelloWorld(RequestContext context) async {
    return 'Hello, World!';
  }
}
```

:::

  </template>
  <template #database>
<CodeComparison>
  <template #leftHeader>
    Loxia
  </template>
  <template #leftCode>

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_loxia/serinus_loxia.dart';

@EntityMeta()
class User extends Entity {
  @PrimaryKey(autoIncrement: true)
  final int id;

  @Column()
  final String name;

  const User({required this.id, required this.name});

  static final entity = $UserEntityDescriptor;
}

class AppModule extends Module {
  AppModule() : super(
    imports: [
      LoxiaModule.inMemory(entities: [User.entity]),
      LoxiaModule.features(entities: [User]),
    ],
    controllers: [UserController()],
  );
}
```
  </template>
  <template #leftFooter>
    Loxia is a powerful ORM for Dart that provides a simple and intuitive API for working with databases. It supports multiple database engines and allows you to define your data models using annotations.
  </template>
  <template #rightHeader>
    Drift
  </template>
  <template #rightCode>

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_drift/serinus_drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<List<User>> getAllUsers() => select(users).get();
  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);
}

class AppModule extends Module {
  AppModule() : super(
    imports: [
      DriftModule(AppDatabase(NativeDatabase.memory())),
      DriftModule.forFeature<AppDatabase>(
        daos: (database) => [
          UsersDao(database)
        ], 
      ),
    ],
    controllers: [
      UserController()
    ]
  );
}
```
  </template>
  <template #rightFooter>
    Drift is the most popular ORM for Dart, it provides a powerful and flexible API for working with databases. It supports multiple database engines and allows you to define your data models using Dart code.
  </template>
</CodeComparison>

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
