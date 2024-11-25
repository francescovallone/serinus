# Modules

The modules in Serinus are containers for the different parts of your application. They can contain controllers,  providers, and other modules and allow you to reuse code across your application.

## Creating a module

To create a module, you need to define a class that extends the Module class.

```dart
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [], // Add the modules that you want to import
    controllers: [],
    providers: [],
    middlewares: [],
    exports: []
  );
}
```

`Modules` have the following properties:

| Property | Description |
| --- | --- |
| `imports` | A list of `Module`s you want to import in the current module. |
| `controllers` | A list of `Controller`s you want to include in the module. |
| `providers` | A list of `Provider`s you want to include in the module. |
| `middlewares` | A list of `Middleware`s you want to include in the module. |
| `exports` | A list of `Provider`s you want to export to other modules. |

## Register components asynchronously

Modules can also use the `registerAsync` method to register controllers, providers, and other modules asynchronously. This is useful when you need to perform asynchronous operations to register the components of the module.

For example if you need to initialize the `database` connection before registering the providers.

Also if you use this method, you need to override the fields `import`, `controllers`, `providers`, and `middlewares` with an empty list.

```dart
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule();

  @override
  List<Provider> providers = [];

  @override
  Future<void> registerAsync() async {
    // Register controllers, providers, and other modules asynchronously
  }
}
```
