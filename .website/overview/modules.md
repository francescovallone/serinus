# Modules

The modules in Serinus are designed to behave as containers for the different parts of your application. They can contain controllers, providers, and other modules. This allows you to organize your application in a modular way and to reuse code across different parts of your application.

## Creating a module

To create a module, you need to create a class that extends `Module`.

```dart
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule() : super(
	imports: [], // Add the modules that you want to import
	controllers: [],
	providers: [],
	middlewares: []
  );
}
```

In the `AppModule` class, you can pass the following parameters to the `super` constructor:

- `imports`: A list of modules that you want to import in the current module.
- `controllers`: A list of controllers that you want to include in the module.
- `providers`: A list of providers that you want to include in the module.
- `middlewares`: A list of middlewares that you want to include in the module.

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
