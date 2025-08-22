---
title: Transformation & Validation Pipes
sidebar: false
editLink: false
search: false
---
<script setup>
	import BlogPage from '../../components/blog_page.vue'
</script>

<BlogPage
	title="Transformation & Validation Pipes"
	author="Francesco Vallone"
	date="21 Aug 2025"
  lastUpdated="21 Aug 2025"
	shadow
>

This document outlines a proposed Pipe system for Serinus that integrates with the existing validation methods to provide a flexible and composable approach to data validation and transformation.

## Requirements

- They should be added easily to a Route, Controller or to the whole application.
- They should allow the user to define their own validation approach.
- The value got from the pipes should be used for the body in the route.
- It should allow to validate all types of body.

## Design Overview

The Pipe system follows Serinus's existing patterns (similar to hooks and middleware) while providing the flexibility needed for data transformation and validation. Pipes execute in a predictable order and can be chained together for complex validation scenarios.

To maximize flexibility and simplify framework implementation, the Pipe system should operate directly on the `RequestContext`. This allows each pipe to access and mutate any part of the request (body, query, params, headers, session) without strict value passing.

## 1. Integration Points

- Pipes can be attached globally, per controller, or per route.
- All pipes receive the full `RequestContext` and can operate on any property.
- Pipes are executed in order before the route handler.

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
  List<Pipe> pipes = [];
  
  // ... existing code
}
```

**Usage:**
```dart
class UserController extends Controller {
  @override
  List<Pipe> pipes = [AuthPipe(), LoggingPipe()];
}
```

### C. Application Level Pipes

Add global pipes to `ApplicationConfig`:

```dart
// Add to ApplicationConfig:
final class ApplicationConfig {
  /// Global pipes for the entire application
  final List<Pipe> globalPipes = [];

}
```

**Usage:**
```dart
void main() async {
  final app = await serinus.createApplication(entrypoint: AppModule());
  app.use(GlobalValidationPipe());
  await app.serve();
}
```

## 2. Execution Flow

Pipes execute in the following order:

1. **Application-level pipes** (global)
2. **Controller-level pipes** 
3. **Route-level pipes**
4. **Route handler execution**

This integration occurs in the existing request handling flow right after body parsing but before route handler execution, similar to how ParseSchema currently works.

## 3. Custom Pipe Examples

### Email Validation Pipe
```dart
import 'package:acanthis/acanthis.dart';

class EmailValidationPipe extends Pipe<String, String> {

  final validator = string().email();

  @override
  Future<String> transform(RequestContext context) async {
    final value = validator.tryParse(context.body.value);
    if (!value.success) {
      throw BadRequestException(message: 'Invalid email format');
    }
    return value.toLowerCase();
  }
}
```

### Object Transformation Pipe
```dart
class UserCreationPipe extends Pipe {
  @override
  Future<void> transform(RequestContext context) async {
    final value = context.body.value;
    context.body = CustomBody<UserDto>(UserDto(
      name: value['name'],
      email: value['email'],
      createdAt: DateTime.now(),
      createdBy: context.use<AuthService>().currentUser.id,
    ));
  }
}
```

### Complex Validation Pipe
```dart
class UserValidationPipe extends Pipe {
  @override
  Future<void> transform(RequestContext context) async {
    // Custom validation logic
    final value = context.body.value;
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

## 4. Complete Usage Example

```dart
class UserController extends Controller {
  UserController({super.path = '/users'}) {
    // Route with multiple pipes
    on(
      Route.post('/'),
      _createUser,
      body: UserDto,
      pipes: [
        UserValidationPipe(),
        UserCreationPipe(),
      ]
    );
    
    // Route with simple validation
    on(
      Route.patch('/<id>/email'),
      _updateEmail,
      body: String,
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

## 5. Benefits

- **Maximum Flexibility:** Pipes can operate on any part of the request.
- **Simple Framework Logic:** No need to orchestrate value passing.
- **Composable:** Pipes can be chained and reused.
- **No Type Restrictions:** Pipes can validate, transform, or enrich context as needed.
- **Consistent API:** All pipes use the same method signature.
- **Existing Pattern:** Follows the same pattern as hooks and middleware.
- **Backward Compatible:** Existing routes continue to work without modification.
- **Reusable:** Pipes can be shared across different routes and controllers.
- **Testable:** Each pipe can be unit tested independently.

## 6. Error Handling

Pipes can throw any `SerinusException` which will be handled by the existing error handling system:

```dart
class StrictValidationPipe extends Pipe {
  @override
  Future<void> transform(RequestContext context) async {
    final value = context.body.value;
    if (value.isEmpty) {
      throw BadRequestException(message: 'Body cannot be empty');
    }
    
    if (value.containsKey('forbidden_field')) {
      throw BadRequestException(message: 'Forbidden field detected');
    }
    
    return value;
  }
}
```

## 7. Performance Considerations

- Pipes execute sequentially in the defined order
- Each pipe transformation is awaited before proceeding to the next
- Minimal runtime overhead compared to existing ParseSchema execution

</BlogPage>