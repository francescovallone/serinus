# Breaking Changes

This page contains a list of breaking changes introduced in the latest version of the framework.

## 1. Renamed `DeferredProvider` to `ComposedProvider`

The `ComposedProvider` is now the preferred way to create providers that depend on other providers.

::: info
Also the factory constructor `Provider.deferred` has been renamed to `Provider.composed`.
:::

The reason for this change is to provide a more intuitive naming convention that better reflects the purpose and behavior of the provider.

```dart
class AppModule extends Module {
  
    AppModule(): super(
        providers: [
            Provider.deferred( // [!code --]
                (AppProvider appProvider) => SecondProvider(appProvider), // [!code --]
                inject: [AppProvider], // [!code --]
                type: SecondProvider // [!code --]
            ), // [!code --]
            Provider.composed( // [!code ++]
                (AppProvider appProvider) => SecondProvider(appProvider), // [!code ++]
                inject: [AppProvider], // [!code ++]
                type: SecondProvider // [!code ++]
            ) // [!code ++]
        ]
    )

}
```

## 2. Controller path is now a required parameter

Every controller must now specify its path explicitly. This change improves clarity and ensures that all routes are clearly defined.

```dart
class AppController extends Controller {
  
    AppController() : super(path: '/'); // [!code --]
    AppController() : super('/'); // [!code ++]

}
```

## 3. View Engine now has just a single method for rendering templates

The View Engine has been simplified to provide just a single method for rendering templates. This change reduces complexity and makes it easier to work with views.

```dart
class MustacheViewEngine extends ViewEngine {

    Future<String> render(View view) async {}
    Future<String> renderString(ViewString view) async {} // [!code --]

}
```

## 4. View and ViewString are now one single class

The `View` and `ViewString` classes have been merged into a single `View` class. This change simplifies the API and makes it easier to work with views.

```dart
class AppController extends Controller {
  
    AppController() : super('/') {
        on(Route.get('/template'), (context) {
            return View('template', {}); // [!code --]
            return View.template('templateName', {}); // [!code ++]
        });
        on(Route.get('/string'), (context) {
            return View('string', {}); // [!code --]
            return View.string('string', {}); // [!code ++]
        });
    }

}
```

## 5. Middlewares are now registered using a fluent API

Middleware registration has been simplified to use a fluent API. This change makes it easier to register multiple middlewares in a more readable way.

Also Middlewares does not have the field `routes` anymore.

```dart
class AppModule extends Module {

    AppModule() : super(
        middlewares: [ // [!code --]
            LogMiddleware( // [!code --]
                routes: ['*'] // [!code --]
            ) // [!code --]
        ] // [!code --]
    );

    void configure(MiddlewareConsumer consumer) { // [!code ++]
        consumer.apply(LogMiddleware()).forRoutes([ // [!code ++]
            RouteInfo( // [!code ++]
                '*' // [!code ++]
            ) // [!code ++]
        ]); // [!code ++]
    } // [!code ++]

}
```

::: info
Other stuff has changed as well, including improvements to the overall architecture and performance optimizations. But to know all the changes you can head to the [Middleware](/middlewares) page.
:::

## 6. The `registerAsync` method now must return a `DynamicModule`

The `registerAsync` method in modules now must return a `DynamicModule`. This change ensures that asynchronous module registration is handled consistently and allows for better integration with the dependency injection system.

```dart
class AppModule extends Module {

    Future<DynamicModule> registerAsync() async {
        return DynamicModule(
            imports: [
                // other modules
            ],
            providers: [
                // providers
            ]
        );
    }

}
```

## 7. Body parsing has been reworked

Body handling has always been a complex topic in Serinus because of the many different types of bodies that can be handled.
To improve type safety, clarity, and maintainability, the definition of the body types has been completely reworked.

As before you can still use the body parameter in your route handler to get directly the body of the request as argument for the handler function.

But you can also ask the request context to parse the body in a specific way.

```dart
on(Route.post('/json'), (context) async {
    final body = await context.bodyAs<Map<String, dynamic>>(); // to parse the body as JSON
    return body;
});
on(Route.post('/text'), (context) async {
    final body = await context.bodyAs<String>(); // to parse the body as plain text
    return body;
});
on(Route.post('/form'), (context) async {
    final body = await context.bodyAs<FormData>(); // to parse the body as form data
    return body;
});
```

## 8. Request and Response Hooks are now divided

To improve clarity and separation of concerns, the request and response hooks have been divided into distinct mixins.

```dart
class TestHook with
    OnRequestResponse // [!code --]
    OnResponse, // [!code ++]
    OnRequest // [!code ++]
    {
        
    }
```

## 9. All Hooks have different method signatures now

Some hooks have their method signatures changed to improve consistency and clarity. In the case of the `onResponse` and `afterHandle` the data value has been changed with an utility class called `WrappedResponse` that can be used to change the response dynamically from the hook if it is required.

```dart
Future<void> onRequest(Request request, InternalResponse response); // [!code --]
Future<void> onRequest(ExecutionContext context); // [!code ++]

Future<void> onResponse(Request request, dynamic data, ResponseProperties properties); // [!code --]
Future<void> onResponse(ExecutionContext context, WrappedResponse data); // [!code ++]

Future<void> afterHandle(RequestContext context, dynamic response); // [!code --]
Future<void> afterHandle(ExecutionContext context, WrappedResponse response); // [!code ++]

Future<void> beforeHandle(RequestContext context); // [!code --]
Future<void> beforeHandle(ExecutionContext context); // [!code ++]
```

## 10. Renamed `ResponseProperties` to `ResponseContext`

To ensure consistency with the naming conventions used throughout the framework, the `ResponseProperties` class has been renamed to `ResponseContext`. This change helps to clarify the purpose of the class and its role in managing the context of a response.

## 11. The Logger has been refactored

The Logger has been refactored to provide a more consistent and flexible API. This change improves the overall logging experience and makes it easier to integrate logging into your application.

But let's check what you should know about the new Logger API since there are some breaking changes.

First of all the `loggerService` parameter has been replaced by the `logger` parameter, also the `loggingLevel` is now a `Set<LogLevel>` and has been renamed `logLevels`.

```dart
void main(List<String> arguments) async {
  final application = await serinus.createApplication(
      entrypoint: AppModule(),
      host: InternetAddress.anyIPv4.address,
      loggerService: null, // [!code --]
      loggingLevel: LogLevel.info // [!code --]
      logger: ConsoleLogger(prefix: 'Serinus New Logger'), // [!code ++]
      logLevels: {LogLevel.info} // [!code ++]
    );
  await application.serve();
}
```

You can learn more about the new logger in the [documentation](/techniques/logging) page.

## 12. SerinusExceptions message is now a required parameter

The `message` parameter in the `SerinusException` class is now required. This change removes verbosity and improves the clarity of exception handling.

```dart
throw BadGatewayException(message: 'Failed to retrieve template'); // [!code --]
throw BadGatewayException('Failed to retrieve template'); // [!code ++]
```

## 13. Global definitions are now module-scoped

In a move to enhance modularity and testability, providers can no longer be registered as global instances. Instead this "job" is delegated to the Module itself.

```dart
class TestProvider extends Provider {

    @override
    bool get isGlobal => true; // [!code --]

}

class TestModule extends Module {

    @override
    bool get isGlobal => true; // [!code ++]

}
```

## 14. Hooks, Pipes and Middlewares now use the `ExecutionContext`

Hooks, Pipes and Middlewares now receive an `ExecutionContext` as their first argument. This context contains information about the current request, response, and other relevant data.
The reason behind this abstraction is to provide an unified API for these components for common requests, websockets, and other types of interactions.

`ExecutionContext` exposes the properties of the current processing context by using a `ArgumentsHost`. The `ArgumentsHost` is an interface that contains the current internals objects for the current context.

Currently the available sub-classes of `ArgumentsHost` are:

- `HttpArgumentsHost`: for HTTP requests.
- `WsArgumentsHost`: for WebSocket requests.
- `SseArgumentsHost`: for Server-Sent Events requests.
- `RpcArgumentsHost`: for RPC requests.

This change unify the way to access the current request and response objects across different types of interactions.

```dart
class TestMiddleware extends Middleware {

    @override
    Future<void> use(ExecutionContext context, NextFunction next) async {
        final argumentsHost = context.argumentsHost;
        if (argumentsHost is HttpArgumentsHost) {
            final request = argumentsHost.request;
            // You can also use context.getType() to know the current context type
            await next();
        }
    }

}
```

## 15. Routes does not have lifecycle hooks anymore

Routes does not have lifecycle hooks anymore. Instead they have access to route-scoped hooks, that can be used to apply hooks to specific routes.

```dart
class HookedRoute extends Route {

    HookedRoute() {
        hooks.add(TestHook());
    }
    
}
```

## 16. ParseSchema has been removed

Although the `ParseSchema` pipe was a useful tool for validating and parsing request bodies, it had some limitations and its usability could be improved.

To address these issues, the `ParseSchema` has been removed and replaced with a more flexible and powerful approach to schema validation.

```dart
on(
    Route.post(
        '/data', 
        pipes: {} // [!code ++]
    ),
    schema: AcanthisParseSchema(), // [!code --]
    (context) async {
        return data;
    }
);
```

Now you can use any pipe to validate and parse request bodies, query parameters, path parameters and whatever you like, giving you more control over the validation process and allowing you to use different validation libraries or custom logic as needed.

## Other Changes

### a. Headers are now a separate class

The headers in the framework have been refactored into a separate class. This change improves type safety and makes it easier to work with different header types.

It shouldn't change the way you access headers in your application but it does provide a more structured way to work with them.

### c. Default Status Code

Serinus now set the status code to 201 for POST requests by default and 200 for all other requests.
This change aligns with common RESTful API practices and improves the clarity of responses.
