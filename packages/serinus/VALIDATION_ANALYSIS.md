# Pipe System Design for Serinus

This document outlines a proposed Pipe system for Serinus that integrates with the existing validation methods to provide a flexible and composable approach to data validation and transformation.

## Requirements

- They should be added easily to a Route, Controller or to the whole application.
- They should allow the user to define their own validation approach.
- The value got from the pipes should be used for the body in the route.
- It should allow to validate all types of body.

## Design Overview

The Pipe system follows Serinus's existing patterns (similar to hooks and middleware) while providing the flexibility needed for data transformation and validation. Pipes execute in a predictable order and can be chained together for complex validation scenarios.

## 1. Core Pipe Interface

```dart
/// The abstract [Pipe] class for data transformation and validation
abstract class Pipe<T, R> {
  /// Transform and validate the input data
  Future<R> transform(T value, RequestContext context);
}
```

## 2. Built-in Pipe Implementations

### ValidationPipe
```dart
/// A pipe that validates using ParseSchema
class ValidationPipe<T> extends Pipe<T, T> {
  final ParseSchema schema;
  
  const ValidationPipe(this.schema);
  
  @override
  Future<T> transform(T value, RequestContext context) async {
    // Use existing ParseSchema validation logic
    final result = await schema.tryParse(value: {'body': value});
    return result['body'] as T;
  }
}
```

### TransformPipe
```dart
/// A pipe that transforms data using a custom function
class TransformPipe<T, R> extends Pipe<T, R> {
  final Future<R> Function(T value, RequestContext context) transformer;
  
  const TransformPipe(this.transformer);
  
  @override
  Future<R> transform(T value, RequestContext context) async {
    return await transformer(value, context);
  }
}
```

### ParseJsonPipe
```dart
/// A pipe that parses JSON strings to objects
class ParseJsonPipe extends Pipe<String, Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> transform(String value, RequestContext context) async {
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      throw BadRequestException(message: 'Invalid JSON format');
    }
  }
}
```

## 3. Integration Points

### A. Route Level Pipes

Extend the existing `RouteHandler` typedef to include pipes:

```dart
// In Controller.on method, extend the RouteHandler typedef:
typedef RouteHandler = ({
  Route route,
  dynamic handler,
  ParseSchema? schema,
  Type? body,
  List<Pipe>? pipes  // New field
});
```

**Usage:**
```dart
class UserController extends Controller {
  UserController({super.path = '/users'}) {
    on(
      Route.post('/'),
      _createUser,
      pipes: [ValidationPipe(userValidationSchema), TransformPipe(_transformUser)]
    );
  }
}
```

### B. Controller Level Pipes

Add a `pipes` getter to the `Controller` class:

```dart
// Add to Controller class:
abstract class Controller {
  /// Global pipes for all routes in this controller
  List<Pipe> get pipes => [];
  
  // ... existing code
}
```

**Usage:**
```dart
class UserController extends Controller {
  @override
  List<Pipe> get pipes => [AuthPipe(), LoggingPipe()];
}
```

### C. Application Level Pipes

Add global pipes to `ApplicationConfig`:

```dart
// Add to ApplicationConfig:
final class ApplicationConfig {
  /// Global pipes for the entire application
  final List<Pipe> globalPipes = [];
  
  // Method to add global pipes
  void addPipe(Pipe pipe) {
    globalPipes.add(pipe);
  }
}
```

**Usage:**
```dart
void main() async {
  final app = await serinus.createApplication(entrypoint: AppModule());
  app.addPipe(GlobalValidationPipe());
  await app.serve();
}
```

## 4. Execution Flow

Pipes execute in the following order:

1. **Application-level pipes** (global)
2. **Controller-level pipes** 
3. **Route-level pipes**
4. **Route handler execution**

This integration occurs in the existing request handling flow right after body parsing but before route handler execution, similar to how ParseSchema currently works.

## 5. Implementation in Route Execution Context

```dart
// In RouteExecutionContext, add pipe execution:
class RouteExecutionContext {
  Future<dynamic> _executePipes(
    dynamic bodyValue, 
    RequestContext context, 
    RouteContext routeContext
  ) async {
    dynamic currentValue = bodyValue;
    // Execute application-level pipes
    for (final pipe in routeContext.pipes) {
      currentValue = await pipe.transform(currentValue, context);
    }
    return currentValue;
  }
}
```

## 6. Custom Pipe Examples

### Email Validation Pipe
```dart
import 'package:acanthis/acanthis.dart';

class EmailValidationPipe extends Pipe<String, String> {

  final validator = string().email();

  @override
  Future<String> transform(String value, RequestContext context) async {
    final value = validator.tryParse(value);
    if (!value.success) {
      throw BadRequestException(message: 'Invalid email format');
    }
    return value.toLowerCase();
  }
}
```

### Object Transformation Pipe
```dart
class UserCreationPipe extends Pipe<Map<String, dynamic>, UserDto> {
  @override
  Future<UserDto> transform(Map<String, dynamic> value, RequestContext context) async {
    return UserDto(
      name: value['name'],
      email: value['email'],
      createdAt: DateTime.now(),
      createdBy: context.use<AuthService>().currentUser.id,
    );
  }
}
```

### Complex Validation Pipe
```dart
class UserValidationPipe extends Pipe<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> transform(Map<String, dynamic> value, RequestContext context) async {
    // Custom validation logic
    if (value['age'] != null && value['age'] < 18) {
      throw BadRequestException(message: 'User must be at least 18 years old');
    }
    
    // Check for duplicate email
    final userService = context.use<UserService>();
    if (await userService.emailExists(value['email'])) {
      throw ConflictException(message: 'Email already exists');
    }
    
    return value;
  }
}
```

## 7. Complete Usage Example

```dart
class UserController extends Controller {
  UserController({super.path = '/users'}) {
    // Route with multiple pipes
    on(
      Route.post('/'),
      _createUser,
      pipes: [
        ValidationPipe(userValidationSchema),
        UserValidationPipe(),
        UserCreationPipe(),
      ]
    );
    
    // Route with simple validation
    on(
      Route.patch('/<id>/email'),
      _updateEmail,
      pipes: [EmailValidationPipe()]
    );
  }
  
  Future<User> _createUser(RequestContext context, UserDto userDto) async {
    // userDto is already validated and transformed by pipes
    return userService.create(userDto);
  }
  
  Future<User> _updateEmail(RequestContext context, String email) async {
    // email is already validated and normalized by EmailValidationPipe
    final userId = context.params['id'];
    return userService.updateEmail(userId, email);
  }
}
```

## 8. Benefits

1. **Easy Integration**: Pipes can be added at route, controller, or application level
2. **Flexible Validation**: Users can define custom validation logic through custom Pipe implementations
3. **Body Transformation**: The transformed value from pipes becomes the new body value for the route handler
4. **Type Safety**: Generic types ensure type safety throughout the transformation chain
5. **Composable**: Multiple pipes can be chained together
6. **Existing Pattern**: Follows the same pattern as hooks and middleware
7. **Backward Compatible**: Existing routes continue to work without modification
8. **Reusable**: Pipes can be shared across different routes and controllers
9. **Testable**: Each pipe can be unit tested independently

## 9. Integration with Existing Features

### With ParseSchema
```dart
// Pipes can work alongside existing ParseSchema
on(
  Route.post('/users'),
  _createUser,
  schema: AcanthisParseSchema(
    query: object({'page': number()}),
  ),
  pipes: [UserValidationPipe(), UserCreationPipe()]
);
```

### With Hooks
```dart
// Pipes execute before hooks
class LoggingHook extends Hook with OnBeforeHandle {
  @override
  Future<void> beforeHandle(RequestContext context) async {
    // This runs after pipes have transformed the body
    print('Body after pipes: ${context.body.value}');
  }
}
```

### With Middleware
```dart
// Middleware runs before pipes
class AuthMiddleware extends Middleware {
  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    // Authenticate user first
    await authenticateUser(context);
    return next();
  }
}
```

## 10. Error Handling

Pipes can throw any `SerinusException` which will be handled by the existing error handling system:

```dart
class StrictValidationPipe extends Pipe<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> transform(Map<String, dynamic> value, RequestContext context) async {
    if (value.isEmpty) {
      throw BadRequestException(message: 'Body cannot be empty');
    }
    
    if (value.containsKey('forbidden_field')) {
      throw ForbiddenException(message: 'Forbidden field detected');
    }
    
    return value;
  }
}
```

## 11. Performance Considerations

- Pipes execute sequentially in the defined order
- Each pipe transformation is awaited before proceeding to the next
- Type checking happens at compile time with generics
- Minimal runtime overhead compared to existing ParseSchema execution

## 12. Migration Path

1. **Phase 1**: Add pipe infrastructure without breaking changes
2. **Phase 2**: Provide built-in pipes (ValidationPipe, TransformPipe, etc.)
3. **Phase 3**: Encourage migration from direct ParseSchema usage to pipes
4. **Phase 4**: Consider deprecating direct ParseSchema in favor of ValidationPipe

This design provides a powerful, flexible, and intuitive way to handle data validation and transformation in Serinus applications while maintaining compatibility with existing code.