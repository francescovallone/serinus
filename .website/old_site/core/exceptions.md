# Exceptions

Since Serinus is a web framework, it has to deal with a lot of different errors that can happen during the request lifecycle. To make it easier to handle these errors, Serinus provides a way to create custom exceptions that can be thrown and caught in the application.

## Built-in Exceptions

Serinus provides a set of built-in exceptions that you can use to handle common errors in your application. These exceptions are:

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

## Creating a Custom Exception

To create a custom exception, you need to create a class that extends the `SerinusException` class. The `SerinusException` class has a constructor that takes a message and a status code as parameters.

```dart
import 'package:serinus/serinus.dart';

class MyException extends SerinusException {
  MyException({super.message, super.statusCode = 500});
}
```

In the `MyException` class, you can override the `message` and `statusCode` properties to customize the exception message and status code.
