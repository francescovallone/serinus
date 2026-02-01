<script setup>
	import ProvidersImage from './components/providers.vue'
</script>

# Providers

Providers are a core concept in Serinus. They are used to manage dependencies and share data and logic across your application.

Providers are registered in a module and can be exported to other modules or injected into other providers. Providers can also be global, meaning they are available to all modules.

<ProvidersImage />

When a provider is registered in a module, it is available to all controllers and routes in that module and it can be accessed in the controllers using the `Context` object.

## Services

Let's start with a simple example of a provider, a service.

A service is a class that contains business logic and data that can be shared across your application.

```dart
import 'package:serinus/serinus.dart';

class NotesService extends Provider {
  NotesService();

  List<String> _notes = [];
  
  void add(String note) {
    _notes.add(note);
  }

  List<String> getNotes() {
    return _notes;
  }
}
```

::: tip
To create a provider using the CLI, you can use the `serinus generate provider` command.
:::

Currently our provider is a simple class that contains a list of notes and two methods to add and get notes.

Before we use it inside our controllers we have to register it in a module.

```dart
import 'package:serinus/serinus.dart';

class NotesModule extends Module {
  NotesModule() : super(
    providers: [
      NotesService(),
    ],
  );
}
```

Now we can use the `NotesService` in our controllers.

```dart
import 'package:serinus/serinus.dart';

class NotesController extends Controller {
  NotesController(): super(path: '/notes') {
    on(Route.get('/'), getNotes);
    on(Route.post('/'), body: Map<String, dynamic>, addNote);
  }

  Future<List<String>> getNotes(RequestContext context) async {
    final notes = context.use<NotesService>().getNotes();
    return notes;
  }

  Future<void> addNote(RequestContext context, Map<String, dynamic> body) async {
    final note = body['note'] as String;
    context.use<NotesService>().add(note);
  }
}
```

## Global Providers

Sometimes you need to share data or logic across your application. In this case, you can create a global provider.

```dart
import 'package:serinus/serinus.dart';

class MyProvider extends Provider {
  MyProvider() : super(isGlobal: true);
}
```

This is the case if you want to share a configuration object or a service across your application.

## Composed Providers

Composed Providers are a the answer of Serinus to Dependency Injection. They are used to inject dependencies into your providers.

Let's, for a second, think of a scenario where we have a `UserService` that needs a `DatabaseService` to work. We can inject the `DatabaseService` into the `UserService` that will be initialized by a ComposedProvider.

```dart
import 'package:serinus/serinus.dart';

class DatabaseService extends Provider {
  DatabaseService();

  void connect() {
    // Connect to the database
  }

  Map<String, dynamic> getById(String id) {
    // Get the data from the database
  }

}

class UserService extends Provider {

  final DatabaseService databaseService;

  UserService(this.databaseService);

  User getUser(String id) {
    // Get the user from the database
    final data = databaseService.getById(id);
    return User.fromJson(data);
  }
}

class UsersModule extends Module {
  UsersModule() : super(
    providers: [
      DatabaseService(),
      Provider.composed<UserService>(
        (CompositionContext context) async => UserService(
          context.use<DatabaseService>()
        ),
        inject: [DatabaseService],
      )
    ],
  );
}
```

These kind of providers will be initialzied asynchrounously and the `create` method will be called only when all the dependencies are resolved.

## Class Providers

Usually, when dealing with multiple environments (development, staging, production), you might want to have different implementations of the same service.

```dart
import 'package:serinus/serinus.dart';

abstract class PaymentService extends Provider {
  PaymentService();
  Future<void> processPayment(double amount);
}

class StripePaymentService extends PaymentService {
  StripePaymentService();

  @override
  Future<void> processPayment(double amount) async {
    // Process payment with Stripe
  }
}

class PaypalPaymentService extends PaymentService {
  PaypalPaymentService();

  @override
  Future<void> processPayment(double amount) async {
    // Process payment with PayPal
  }
}
```

You can register different implementations of the same service using Class Providers.

```dart
import 'package:serinus/serinus.dart';

class PaymentsModule extends Module {
  PaymentsModule(String environment) : super(
    providers: [
      Provider.forClass<PaymentService>(
        useClass: environment == 'production'
          ? StripePaymentService()
          : PaypalPaymentService(),
      ),
    ],
  );
}

PaymentsModule('production') // Will use StripePaymentService
PaymentsModule('development') // Will use PaypalPaymentService
```

## Value Providers

Value Providers are used to register a constant value or an object that doesn't require any initialization logic.

```dart
import 'package:serinus/serinus.dart';

class Config {
  final String apiUrl;
  final String apiKey;

  Config(this.apiUrl, this.apiKey);
}

class ConfigModule extends Module {
  ConfigModule() : super(
    providers: [
      Provider.forValue<Config>(
        Config('https://api.example.com', 'my-api-key'),
      ),
    ],
  );
}
```

If you need to differentiate multiple value providers of the same type, you can use the optional `name` parameter.

```dart
import 'package:serinus/serinus.dart';

class ConfigModule extends Module {
  ConfigModule() : super(
    providers: [
      Provider.forValue<Config>(
        Config('https://api.example.com', 'my-api-key'),
        name: 'production',
      ),
      Provider.forValue<Config>(
        Config('https://staging-api.example.com', 'my-staging-api-key'),
        name: 'staging',
      ),
    ],
  );
}
```

Ok, now we know how to register different value providers of the same type, but how can we use them?

If you want to export a named value provider from a module, you can use the `Export` class with the `name` parameter.

```dart
import 'package:serinus/serinus.dart';

class ConfigModule extends Module {
  ConfigModule() : super(
    providers: [
      Provider.forValue<Config>(
        Config('https://api.example.com', 'my-api-key'),
        name: 'production',
      ),
      Provider.forValue<Config>(
        Config('https://staging-api.example.com', 'my-staging-api-key'),
        name: 'staging',
      ),
    ],
    exports: [
      Export.value<Config>('production'),
      Export.value<Config>('staging'),
    ],
  );
}
```

If you want to use a named value provider in a controller or another provider, you can use the `name` parameter of the `use` method.

```dart
import 'package:serinus/serinus.dart';

class SomeController extends Controller {
  SomeController(): super(path: '/some') {
    on(Route.get('/'), getConfig);
  }

  Future<Config> getConfig(RequestContext context) async {
    final config = context.use<Config>(name: 'production');
    return config;
  }
}
```

::: tip
We recommend using always named value providers because they provide a more explicit way to manage different values in your application.
:::

## Lifecycle Hooks

If you need to run some code when your application is initializing, bootstrapping, ready to serve requests, or shutting down, you can use lifecycle hooks in your providers.

There are four lifecycle hooks available:

| Mixin | Hook                | Description                                                                 |
|-------|---------------------|-----------------------------------------------------------------------------|
| `OnApplicationInit` | `onApplicationInit` | Called when the application is initializing itself and the provider is registered   |
| `OnApplicationBootstrap` | `onApplicationBootstrap`      | Called when the application is initialized and all the provider (even the deferred) are registered |
| `OnApplicationReady` | `onApplicationReady`      | Called when the application is ready to serve requests |
| `OnApplicationShutdown` | `onApplicationShutdown`      | Called when the application is shutting down |

The hooks return a `Future<void>` and can be used to run asynchronous code.

```dart
import 'package:serinus/serinus.dart';

class NotesProvider extends Provider with OnApplicationInit {

  final _notes = <String>[];

  @override
  Future<void> onApplicationInit() async {
    _notes.clear();
  }
}

```
