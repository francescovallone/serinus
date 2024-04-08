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

## Adding guards

Moduls can have guards, and they will be executed before the guards defined in the controllers and routes.
Also if a module has submodules, the guards will be executed before the guards defined in the submodules.

To add a guard to a module, you can override the `guards` getter and add to the list the guards that you need.

```dart
import 'package:serinus/serinus.dart';

class MyGuard extends Guard {
  @override
  Future<bool> canActivate({
	required Request request,
  }) async {
	return true;
  }
}

class AppModule extends Module {
  AppModule() : super(
	imports: [], // Add the modules that you want to import
	controllers: [],
	providers: [],
	middlewares: [],
  );

  @override
  List<Guard> get guards => [MyGuard()];
}
```

## Adding pipes

Modules can have pipes, and they will be executed before the pipes defined in the controllers and routes.
Also if a module has submodules, the pipes will be executed before the pipes defined in the submodules.

To add a pipe to a module, you can override the `pipes` getter and add to the list the pipes that you need.

```dart
import 'package:serinus/serinus.dart';

class MyPipe extends Pipe {
  @override
  Future<void> transform({
	required Request request,
  }) async {
	print('Pipe executed');
  }
}

class AppModule extends Module {
  AppModule() : super(
	imports: [], // Add the modules that you want to import
	controllers: [],
	providers: [],
	middlewares: [],
  );

  @override
  List<Pipe> get pipes => [MyPipe()];
}
```