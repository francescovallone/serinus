# Exception Filters

Exception filters are a powerful mechanism in Serinus that allow you to handle exceptions thrown during the request-response cycle. They provide a way to catch and process exceptions, enabling you to return custom error responses or perform specific actions when an error occurs.

```dart
import 'package:serinus/serinus.dart';

class NotFoundExceptionFilter extends ExceptionFilter {
  NotFoundExceptionFilter() : super(catchTargets: [NotFoundException]);

  @override
  Future<void> onException(ExecutionContext context, Exception exception) async {
    if (exception is NotFoundException) {
      context.response.statusCode = 404;
      context.response.body = {'message': 'Resource not found'};
    }
  }
}
```

In the example above, we create a custom exception filter that catches `NotFoundException` and returns a 404 status code with a custom message.

## Throwing standard exceptions

Serinus provides a built-in `SerinusException` class that you can use to handle errors in your application. This class is the base class for all exceptions in Serinus and provides a way to define custom exceptions with specific status codes and messages.

For example, in the `UserController` class, you can throw a `SerinusException` when the user is not found:

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {

  UserController() : super('/users') {
    on(Route.get('/<id>'), getUser);
  }
  
  Future<User> getUser(RequestContext context) async {
    final userId = context.params['id'];
    final user = await context.use<UserService>().getUserById(userId);
    if (user == null) {
      throw SerinusException('User not found', statusCode: 404);
    }
    return user;
  }

}
```

## Built-in Exceptions

Serinus, by default, provides a set of built-in exceptions that you can use in your application. These exceptions are subclasses of `SerinusException` and are designed to handle common HTTP error scenarios. You can use these exceptions to simplify error handling in your application.
These exceptions are automatically mapped to HTTP status codes, so you don't have to worry about manually setting the status code for each exception.

| Exception | Description | Status Code |
| --- | --- | --- |
| `BadRequestException` | Thrown when the request is invalid. | 400 |
| `UnauthorizedException` | Thrown when the user is not authorized to access the resource. | 401 |
| `ForbiddenException` | Thrown when the user is not allowed to access the resource. | 403 |
| `NotFoundException` | Thrown when the requested resource is not found. | 404 |
| `MethodNotAllowedException` | Thrown when the method is not allowed on the resource. | 405 |
| `ConflictException` | Thrown when there is a conflict with the current state of the resource. | 409 |
| `GoneException` | Thrown when the requested resource is no longer available. | 410 |
| `PreconditionFailedException` | Thrown when the requested resource is no longer available. | 412 |
| `PayloadTooLargeException` | Thrown when the request payload is too large. | 413 |
| `UnsupportedMediaTypeException` | Thrown when the media type is not supported. | 415 |
| `UnprocessableEntityException` | Thrown when the request is valid, but the server cannot process it. | 422 |
| `TooManyRequestsException` | Thrown when the client has sent too many requests in a given amount of time. | 429 |
| `InternalServerErrorException` | Thrown when an internal server error occurs. | 500 |
| `NotImplementedException` | Thrown when the requested feature is not implemented. | 501 |
| `BadGatewayException` | Thrown when the gateway is bad. | 502 |
| `ServiceUnavailableException` | Thrown when the service is unavailable. | 503 |
| `GatewayTimeoutException` | Thrown when the gateway times out. | 504 |

All these exceptions have a `message` field that you can use to provide a custom error message.

```dart
throw BadRequestException('Invalid request format');
```

## Creating a Custom Exception

Let's say you need to add another field to the exception, such as a `errors` field. You can create a custom exception class that extends `SerinusException` and adds the new field:

```dart
import 'package:serinus/serinus.dart';

class CustomException extends SerinusException {
  final List<String> errors;

  CustomException(String message, {required this.errors, int statusCode = 400}) 
    : super(message, statusCode: statusCode);
}
```

And as before, you can throw this exception in your controller:

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {

  UserController() : super('/users') {
    on(Route.get('/<id>'), getUser);
  }
  
  Future<User> getUser(Request request) async {
    final userId = request.params['id'];
    final user = await context.use<UserService>().getUserById(userId);
    if (user == null) {
      throw CustomException('User not found', errors: ['User with id $userId not found'], statusCode: 404);
    }
    return user;
  }

}
```

## Binding Exception Filters

You can bind exception filters at different levels in your application: globally, at the controller level, or at the route level.

### Global Exception Filters

You can bind an exception filter globally to your application using the `use` method on the `SerinusApplication` object.

```dart
import 'package:serinus/serinus.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule()
  );

  // Add the exception filter to the application
  app.use(NotFoundExceptionFilter());

  // Start the application
  await app.serve();
}
```

### Controller Exception Filters

You can also bind an exception filter to a specific controller using the `exceptionFilters` property of the `Controller` class.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {

  List<ExceptionFilter> get exceptionFilters => [NotFoundExceptionFilter()];

  UserController() : super('/users') {
    on(Route.get('/<id>'), getUser);
  }

  Future<User> getUser(RequestContext context) async {
    final userId = context.params['id'];
    final user = await context.use<UserService>().getUserById(userId);
    if (user == null) {
      throw SerinusException('User not found', statusCode: 404);
    }
    return user;
  }
}
```

### Route Exception Filters

You can also bind an exception filter to a specific route using the `exceptionFilters` property of the `Route` class.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {

  UserController() : super('/users') {
    on(
      Route.get(
        '/<id>',
        exceptionFilters: {NotFoundExceptionFilter()}
      ), 
      getUser
    );
  }

  Future<User> getUser(RequestContext context) async {
    final userId = context.params['id'];
    final user = await context.use<UserService>().getUserById(userId);
    if (user == null) {
      throw SerinusException('User not found', statusCode: 404);
    }
    return user;
  }
}
```
