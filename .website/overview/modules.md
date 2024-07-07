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

`Modules` have the following properties::

- `imports`: A list of modules you want to import in the current module.
- `controllers`: A list of controllers you want to include in the module.
- `providers`: A list of providers you want to include in the module.
- `middlewares`: A list of middlewares you want to include in the module.
- `exports`: A list of providers you want to export to other modules.

## Creating a DeferredModule

Modules are loaded instantly when the application starts, but if you need to load a module asynchronously, you can wrap a `Module` with the `DeferredModule` class.
This class has an `inject` property that exposes the providers on which the module depends.
A `DeferredModule` has access to all the properties of the `Module` class, so you can pass the same parameters to the `super` constructor.
Also, it has a `init` property that is a function that will be executed when the module is loaded and that returns a `Module` object.

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

## Registering a module

Modules can also use the `registerAsync` method to register controllers, providers, and other modules asynchronously. This is useful when you need to perform asynchronous operations to register the components of the module.

Also if you use this method, you need to override the fields `import`, `controllers`, `providers`, and `middlewares` with an empty list.

```dart

import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [], // Add the modules that you want to import
    controllers: [],
    providers: [],
    middlewares: []
  );

  @override
  Future<void> registerAsync() async {
    // Register controllers, providers, and other modules asynchronously
  }
}
```