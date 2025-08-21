---
title: Transformation & Validation Pipes
sidebar: false
editLink: false
search: false
head:
    - - meta
      - property: 'og:title'
        content: Transformation & Validation Pipes

    - - meta
      - name: 'description'
        content: Analysis of Transformation & Validation Pipes in Serinus

    - - meta
      - property: 'og:description'
        content: Analysis of Transformation & Validation Pipes in Serinus
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

## Context-Driven Transformation & Validation Pipes

To maximize flexibility and simplify framework implementation, the Pipe system should operate directly on the `RequestContext`. This allows each pipe to access and mutate any part of the request (body, query, params, headers, session) without strict value passing.

### 1. Core Pipe Interface

```dart
/// A generic pipe that operates on the whole RequestContext
abstract class Pipe {
  /// Transform and validate any part of the request context
  Future<void> transform(RequestContext context);
}
```

### 2. Built-in Pipe Implementations (Examples)

#### Query Validation Pipe
```dart
class QueryValidationPipe extends Pipe {
  @override
  Future<void> transform(RequestContext context) async {
    final query = context.query;
    // Validate or transform query parameters
    if (query['page'] != null && int.tryParse(query['page']) == null) {
      throw BadRequestException(message: 'Invalid page parameter');
    }
    // Optionally mutate context.query
    context.query['page'] = int.parse(query['page']);
  }
}
```

#### Header Transformation Pipe
```dart
class HeaderTransformPipe extends Pipe {
  @override
  Future<void> transform(RequestContext context) async {
    // Normalize header keys
    context.headers = context.headers.map((k, v) => MapEntry(k.toLowerCase(), v));
  }
}
```

#### Session Validation Pipe
```dart
class SessionValidationPipe extends Pipe {
  @override
  Future<void> transform(RequestContext context) async {
    if (!context.session.isAuthenticated) {
      throw UnauthorizedException();
    }
  }
}
```

#### Body Validation Pipe
```dart
class BodyValidationPipe extends Pipe {
  final ParseSchema schema;
  BodyValidationPipe(this.schema);

  @override
  Future<void> transform(RequestContext context) async {
    final result = await schema.tryParse(value: {'body': context.body});
    context.body = result['body'];
  }
}
```

### 3. Integration Points

- Pipes can be attached globally, per controller, or per route.
- All pipes receive the full `RequestContext` and can operate on any property.
- Pipes are executed in order before the route handler.

### 4. Benefits

- **Maximum Flexibility:** Pipes can operate on any part of the request.
- **Simple Framework Logic:** No need to orchestrate value passing.
- **Composable:** Pipes can be chained and reused.
- **No Type Restrictions:** Pipes can validate, transform, or enrich context as needed.
- **Consistent API:** All pipes use the same method signature.

### 5. Example Usage

```dart
on(
  Route.get('/users/<id>'),
  getUserHandler,
  pipes: [
    QueryValidationPipe(),
    HeaderTransformPipe(),
    SessionValidationPipe(),
    BodyValidationPipe(userBodySchema),
  ]
);
```

### 6. Error Handling

Any pipe can throw a SerinusException for its source, which will be handled by the framework's error system.

### 7. Migration Path

- Add context-driven pipe support without breaking changes
- Provide built-in pipes for all sources
- Encourage migration from direct ParseSchema usage to pipes

This revised design ensures that Serinus users can validate and transform any part of the request, with maximum flexibility and minimal framework complexity.

---

...existing code...
```