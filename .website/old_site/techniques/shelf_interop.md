# Shelf Interoperability

Shelf is a low-level web server library for Dart. It allows you to handle HTTP requests and responses directly. Shelf is also the most popular web server library for Dart and has a large ecosystem of plugins and middleware ready to use.

For this particular reason and to make Serinus more flexible, we have decided to make Serinus compatible with Shelf. This means that you can use Shelf plugins and middleware in your Serinus applications.

## Usage

To use the Shelf Middlewares or Handlers in your Serinus application, you can use the `Middleware` class.
The class has a factory constructor called `Middleware.shelf` that takes a `shelf.Middleware` or a `shelf.Handler` and returns a Serinus Middleware that can be used in your application.

The `Middleware.shelf` factory constructor allows also to pass a `routes` parameter that is a list of routes where the middleware will be applied.

### Example

```dart
import 'package:serinus/serinus.dart';

import 'package:shelf/shelf.dart' as shelf;

final handler = (req) => shelf.Response.ok('Hello world from shelf');

class AppModule extends Module {
  AppModule() : super(
    imports: [],
    controllers: [],
    providers: [],
    middlewares: [
      Middleware.shelf(handler)
    ]
  );
}
```

In the example above, we are using a Shelf Handler to return a simple response. We are wrapping the Shelf Handler with the `Middleware.shelf` factory constructor to create a Serinus Middleware that can be used in the application.

You can pass to `Middleware.shelf` the following parameters:

| Parameter | Description | Default |
| --- | --- | --- |
| `handler` | The Shelf Middleware or Handler that will be used in the Serinus Middleware. | REQUIRED |
| `routes` | The list of routes where the middleware will be applied. | `[*]` |
| `ignoreResponse` | To ignore the response of the handler or not (If `false` and the handler return a response then the request lifecycle will be interrupted) | `true` |


## Conclusion

Thanks to the interoperability you can now use existing Shelf plugins and middleware in your Serinus applications increasing the capabilities of them to a new level.
