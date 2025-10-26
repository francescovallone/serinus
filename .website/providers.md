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

class NotesProvider with OnApplicationInit {

  final _notes = <String>[];

  @override
  Future<void> onApplicationInit() async {
    _notes.clear();
  }
}

```
