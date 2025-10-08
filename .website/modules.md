# Modules

A module, in Serinus, is a class that extends the `Module` class and is used to organize the application into cohesive blocks of functionality.

Modules can import other modules, controllers, providers, and middlewares, and export providers to other modules.

<img src="/modules.png" alt="Module"/>

Every Serinus application has at least one module, the `entrypoint`, which is the entry point of the application and it can be used to create the graph of dependencies in the application.

::: tip
While in a small application you might want to use only the entrypoint to manage your application, creating different modules is highly recommended to organize your application in a scalable way and to define a clear boundary between the different parts of your application.
:::

The `Module` abstract class exposes the following properties:

| Property | Description |
| --- | --- |
| `imports` | A list of `Module`s you want to import in the current module. |
| `controllers` | A list of `Controller`s you want to include in the module. |
| `providers` | A list of `Provider`s you want to include in the module. |
| `exports` | A list of `Provider`s you want to export to other modules. |

## Shared Modules

Modules can be shared between different modules because Serinus treats them as singletons. This means that the same instance of a module is shared between all the modules that import it.

## Dynamic Modules

Modules can also use the `registerAsync` method to register controllers, providers, and other modules dynamically. This is useful when you need to perform asynchronous operations to register the components of the module.

For example if you need to initialize the `database` connection before registering the providers.

```dart
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule();

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final database = await Database.connect('mongodb://localhost:27017/mydb');
    return DynamicModule(
      controllers: [AppController()],
      providers: [DatabaseService(database)],
    );
  }
}
```

## Example

Here is an example of a module that imports another module, registers a controller, a provider, and exports the provider.

```dart
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule(): super(
    imports: [AuthModule()],
    controllers: [AppController()],
    providers: [AppService()],
    exports: [AppService],
  );
}
```
