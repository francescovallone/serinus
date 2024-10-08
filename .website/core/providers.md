# Providers

Providers, as the name suggests, provide services to the application. They are used to encapsulate the logic of a service, such as a database connection, a cache, or a third-party API.

## Creating a Provider

To create a provider, you simply need to extends the `Provider` class.

```dart
import 'package:serinus/serinus.dart';

class MyProvider extends Provider {
  MyProvider();
}
```

That's it! You have created a provider.

## Injecting a Provider

To inject a provider in the application, you need to add it to the `providers` list in your module.

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

::: tip
You can read more about how Serinus handles the dependency injection in the [Dependency Injection](/foundations/dependency_injection.html) section.
:::

::: code-group

```dart [Simple Usage]
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}){
    on(GetRoute(path: '/'), (context) async {
      return context.use<MyProvider>().myMethod();
    });
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
```

:::

## Global Providers

If you want to make a provider available to all modules, you just have to pass the `isGlobal` parameter as `true` when creating the provider.

```dart
import 'package:serinus/serinus.dart';

class MyProvider extends Provider {
  MyProvider() : super(isGlobal: true);
}
```

## Deferred Providers

By default, all providers are created when the module is created. If you want to create the provider after all the modules are registered, you can extend the `DeferredProvider` class.

This class has a `init` property that accepts a function that returns the provider.

Also the `init` function has access to the application context and contains all the providers initialized.
When a DeferredProvider is initialized, its provider is added to the application context so that it can be used as dependency by other providers. This grant a incremental initialization of the providers.

::: tip
You can also use a shorthand to create a DeferredProvider by using the `Provider.deferred` factory constructor.
This constructor uses the same parameters as the `DeferredProvider` class.
:::

::: code-group

```dart [Deferred Provider]
import 'package:serinus/serinus.dart';

class MyProvider extends Provider {
  final TestProvider testProvider;

  MyProvider(this.testProvider);
}
```

```dart [Module]
import 'package:serinus/serinus.dart';

class MyModule extends Module {
  MyModule() : super(
    providers: [
      TestProvider(),
      DeferredProvider(
        inject: [TestProvider],
        init: (context) async {
          final prov = context.use<TestProvider>();
          return MyProvider(prov);
        }
      ),
    ],
  );
}
```

:::
