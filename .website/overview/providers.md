# Providers

Providers are fundamental in Serinus. A lot of functionalities are treated as providers - services, repositories, factories, etc.

Providers in Serinus are treated as

## Creating a Provider

To create a provider, you simply need to extends the `Provider` class.

```dart
import 'package:serinus/serinus.dart';

class MyProvider extends Provider {
  MyProvider();
}
```

## Using a Provider

To use a provider, you need to add it to the `providers` list in your module.

::: code-group
    
```dart [my_provider.dart]
import 'package:serinus/serinus.dart';

class MyProvider extends Provider {
  MyProvider();
}
```

```dart [my_module.dart]
import 'package:serinus/serinus.dart';
import 'my_provider.dart';

class MyModule extends Module {
  MyModule() : super(
    providers: [
      MyProvider(),
    ],
  );
}
```
:::

Doing this will make the provider available to all controllers and routes in the module and its submodules.
To access the provider, you can use the `context` object when handling the request.

If you want to use a provider from a submodule, you must add the `Type` of the provider in the `exports` list of the submodule.

::: code-group

```dart [Simple Usage]
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'});

  @override
  Future<Response> handle(Request request) async {
    final myProvider = context.get<MyProvider>();
    return Response.text(
      data: 'Hello World!',
    );
  }
}
```

```dart [Exports Module]
import 'package:serinus/serinus.dart';

class OtherModule extends Module {
    OtherModule() : super(
        providers: [MyProvider()]
        exports: [MyProvider],
    );
}

// MyProvider is now available in MyModule
class MyModule extends Module {
  MyModule() : super(
    imports: [OtherModule()],
    providers: [],
  )
}
:::

## Global Providers

If you want to make a provider available to all modules, you just have to pass the `isGlobal` parameter as `true` when creating the provider.

```dart
import 'package:serinus/serinus.dart';

class MyProvider extends Provider {
  MyProvider() : super(isGlobal: true);
}
```


## Lazy Providers

By default, all providers are created when the module is created. If you want to create the provider after all the modules are created, you can extend the `DeferredProvider` class.

This class has a `init` property that accepts a function that returns the provider.

Also the `init` function has access to the application context and contains all the providers initialized.
When a DeferredProvider is initialized, its provider is added to the application context so that it can be used as dependency by other providers. This grant a incremental initialization of the providers.

```dart 
import 'package:serinus/serinus.dart';

class MyDeferredProvider extends DeferredProvider {
  MyDeferredProvider() : super(
    init: (context) => MyProvider(),
  );
}
```
