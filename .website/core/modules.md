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

## Creating a DeferredModule

Modules are loaded instantly when the application starts, but if you need to create a module dependent on providers within the application, you can wrap a `Module` with the `DeferredModule` class.

The `DeferredModule` class takes two parameters:

| Parameter | Description |
| --- | --- |
| `inject` | A list of providers that the module needs to load. |
| `init` | A function that returns a `Module` object. |

It also has access to all the properties of the `Module` class, so you can pass the same parameters to the `super` constructor.

```dart
import 'package:serinus/serinus.dart';

class ModuleWithDependencies extends Module {
  final TestProvider testProvider;
  ModuleWithDependencies(this.testProvider) : super(
    imports: [],
    controllers: [],
    providers: [],
    middlewares: []
  );
}

class AppModule extends Module {
  AppModule(): super(
    imports: [
      DeferredModule(
        inject: [TestProvider],
        (context) async {
          final prov = context.use<TestProvider>();
          return ModuleWithDependencies(prov);
        }
      )
    ],
    controllers: [],
    providers: [TestProvider(isGlobal: true)],
    middlewares: []
  );
}
```

::: warning
The entry point of the application must be a module that extends `Module` and cannot be wrapped by the `DeferredModule` class.
:::

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
