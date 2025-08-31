# Pipes

A pipe is a class annotated which extends the `Pipe` abstract class and override the `transform` method. 

Pipes have two typical use cases:

1. **Data Transformation**: Pipes can be used to transform the input data before it reaches the route handler.
2. **Data Validation**: Pipes can also be used to validate the incoming data by checking its structure, types, or values.

In both cases pipes operate on the `RequestContext` before it reaches the route handler, allowing for a centralized way to manage and manipulate request data.

Serinus comes with a number of built-in pipes that you can use out-of-the-box. You can also build your own custom pipes. In this chapter, we'll introduce the built-in pipes and show how to bind them to route handlers. We'll then examine several custom-built pipes to show how you can build one from scratch.

::: info
When a Pipe throws an exception it is handled by the exceptions layer. Given the above, it should be clear that when an exception is thrown in a Pipe, no other middleware, hooks or route handlers are subsequently executed.
:::

## Built-in Pipes

Serinus comes with a number of built-in pipes that you can use out-of-the-box. These include:

- DefaultValuePipe
- BodySchemaValidationPipe
- ParseDatePipe
- ParseDoublePipe
- ParseIntPipe
- ParseBoolPipe

## Binding pipes

Pipes can be bound to route handlers or controllers in order to process incoming requests.

### Routes

When binding pipes to routes, you can specify them directly in the route handler definition. For example:

```dart
class AppController extends Controller {

    AppController(): super('/') {
        on(
            Route.get('/<id>'), 
            pipes: [
                ParseIntPipe('id', bindingType: PipeBindingType.params)
            ],
            (context) async {
                // Handle the request
            }
        );
    }

}
```

In this example, the `ParseIntPipe` is applied to the `id` route parameter, ensuring that the parameter is parsed as an integer before the route handler is executed.

### Controllers

```dart
class AppController extends Controller {

    @override
    List<Pipe> get pipes => [
        ParseIntPipe('id', bindingType: PipeBindingType.params)
    ]

    AppController(): super('/') {
        on(
            Route.get('/<id>'),
            (context) async {
                // Handle the request
            }
        );
    }

}
```

In this example, the `ParseIntPipe` is applied to all the routes of the `AppController`, ensuring that the parameter is parsed as an integer before the route handler is executed.

## Global Pipes

Pipes, like hooks, can be applied globally to all routes and controllers. This is useful for applying common transformations or validations across your entire application.

To add a global pipe you need to use the same `use` method that you use for hooks in the application.

```dart
Future<void> main() async {
    final application = await serinus.createApplication(
        entrypoint: AppModule(),
        host: InternetAddress.anyIPv4.address,
        logger: ConsoleLogger(prefix: 'Serinus New Logger'),
    );
    application.use(MyGlobalPipe());
    application.serve();
}
```

Once a pipe is added as a global pipe, it will be applied to all incoming requests, regardless of the route or controller.
