# Minimal Application

Serinus is optimal for building scalable and maintainable applications. However, sometimes you just need to drop down to the bare minimum and get things working as quickly as possible. This guide will show you how to create a minimal Serinus application with just a few lines of code.

## Create a Minimal Application

To create a minimal Serinus application, you can use the following code:

```dart
import 'package:serinus/serinus.dart';

Future<void> main() async {
    final application = await serinus.createMinimalApplication();
    await application.serve();
}
```

As you can see, we are using the `createMinimalApplication` method from the Serinus factory to create a new instance of the application. All the parameters are optional and will be set to default values if not provided.

## Add some routes

You can easily add routes to your minimal application using some application methods. Here's an example of how to add a simple route that returns a "Hello, World!" message:

```dart
import 'package:serinus/serinus.dart';

Future<void> main() async {
    final application = await serinus.createMinimalApplication();

    application.get('/hello', (RequestContext context) async {
        return 'Hello, World!';
    });

    await application.serve();
}
```

In this example, we are adding a GET route at the path `/hello` that returns a simple string message. You can add as many routes as you need using the various HTTP methods provided by Serinus.

## Add Middleware

You can also add middleware to your minimal application to handle tasks such as logging, authentication, or request parsing. Here's an example of how to add a simple logging middleware:

```dart
import 'package:serinus/serinus.dart';

Future<void> main() async {
    final application = await serinus.createMinimalApplication();

    application.useMiddleware(LogMiddleware());

    application.get('/hello', (RequestContext context) async {
        return 'Hello, World!';
    });

    await application.serve();
}
```

The minimal application is a great way to quickly get started with Serinus and build simple applications without the need for complex configurations or setups. You can always add more features and functionality as your application grows.

## All minimal application methods

| Methods | Description |
| --- | --- |
| `get` | Creates a new GET route for the given path and handler. |
| `post` | Creates a new POST route for the given path and handler. |
| `put` | Creates a new PUT route for the given path and handler. |
| `delete` | Creates a new DELETE route for the given path and handler. |
| `patch` | Creates a new PATCH route for the given path and handler. |
| `options` | Creates a new OPTIONS route for the given path and handler. |
| `head` | Creates a new HEAD route for the given path and handler. |
| `all` | Creates a new route for all HTTP methods for the given path and handler. |
| `useMiddleware` | Adds a middleware to the application. |
| `provide` | Provides a dependency to the application. |
| `import` | Imports a module into the application. |
| `serve` | Starts serving the application on the configured host and port. |

All of these methods are available on the minimal application instance and can be used to build your application as needed. Also as you can see you can start by using the `provide` and `import` methods to set up your application's dependencies and modules, and when you app grows you can easily move these imports in your entrypoint module and use the `createApplication` method to create a more structured application.
