---
title: Serinus 2.0 - Dawn Chorus
sidebar: false
editLink: false
search: false
outline: [2, 4]
head:
    - - meta
      - property: 'og:title'
        content: Serinus 2.0 - Dawn Chorus

    - - meta
      - name: 'description'
        content: The Serinus 2.0 release introduces Module Composition, OpenAPI enhancements, a revamped Logger, Pipes, Exception Filters, and more.

    - - meta
      - property: 'og:description'
        content: The Serinus 2.0 release introduces Module Composition, OpenAPI enhancements, a revamped Logger, Pipes, Exception Filters, and more.

    - - meta
      - property: 'og:image'
        content: https://serinus.app/blog/serinus_2_0/serinus_2_0.webp

    - - meta
      - property: 'twitter:image'
        content: https://serinus.app/blog/serinus_2_0/serinus_2_0.webp
---

<script setup>
    import BlogPage from '../components/blog_page.vue'
</script>

<BlogPage
    title="Serinus 2.0 - Dawn Chorus"
    src="/blog/serinus_2_0/serinus_2_0.webp"
    alt="Serinus 2.0 - Dawn Chorus"
    author="Francesco Vallone"
    date="01 Nov 2025"
    :tags="['releases']"
    shadow
>

Serinus 2.0, named "Dawn Chorus," marks a significant milestone in our journey to provide a robust and flexible framework for building scalable server-side applications with Dart. This release introduces several new features and improvements that enhance the developer experience and expand the capabilities of Serinus.

## New Features

### Module Composition

One of the things we wanted to achieve with Serinus 2.0 is to make modules more flexible and adaptable to different contexts. But there was a challenge: modules often need to configured differently based on the environment or specific application requirements. For example, you might want to provide different API keys, database connections, or other configurations depending on whether you're in development, staging, or production.

To address this challenge, we introduced the concept of Composed Modules. Composed Modules allow developers to create modules that can be configured at runtime, making it easier to adapt to different environments and requirements.

```dart
class ConfigurableModule extends Module {
  final String apiKey;

  ConfigurableModule(this.apiKey) : super(
    providers: [
      ApiServiceProvider(apiKey),
    ],
  );
}

class AppModule extends Module {
  AppModule() : super(
    imports: [
      Module.composed<ConfigurableModule>(
      (CompositionContext context) async {
        final config = context.get<ConfigService>();
        return ConfigurableModule(config.apiKey);
      },
      injects: [ConfigService],
      ),
    ],
    controllers: [
      AppController(),
    ],
    providers: [],
  );
}
```

This feature should greatly enhance the modularity and reusability of Serinus modules, allowing developers to create more dynamic and adaptable applications.

### OpenAPI Enhancements

One of the most discussed topic in the Dart community for backend frameworks is reliable OpenAPI support. With Serinus 2.0, we have made significant strides in this area by introducing a more robust and flexible OpenAPI module.

The module automatically map Serinus routes and handlers to OpenAPI specifications making it one of the most seamless integrations available in the Dart ecosystem.

```dart
import 'package:serinus_openapi/serinus_openapi.dart';
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [
      OpenApiModule.v3(
        InfoObject(
          title: 'Serinus OpenAPI Example',
          version: '1.0.0',
          description: 'An example of Serinus with OpenAPI integration',
        ),
        analyze: true, // Enable automatic analysis of routes
        renderer: SwaggerUIOptions(), // Use Swagger renderer
      )
    ],
    controllers: [
      AppController(),
    ],
    providers: [],
  );
}
```

With these changes, we belive that calling the plugin `serinus_swagger` is no longer appropriate, as it now supports multiple renderers and a more comprehensive OpenAPI integration. Therefore, we have renamed the package to `serinus_openapi` to better reflect its capabilities.

Although this feature is still in its early stages, we are committed to expanding its capabilities and providing a comprehensive solution for API documentation and client generation.

Also, Serinus 2.0 introduces support for multiple OpenAPI renderers, allowing developers to choose between popular options like Swagger and Scalar. This flexibility ensures that developers can select the renderer that best fits their project's needs.

### Revamped Logger

The Logger in Serinus 2.0 has been completely revamped to provide a more powerful logging experience. The new Logger can be easily extended to support custom log formats, outputs, and integrations with third-party logging services. This flexibility allows developers to tailor the logging system to their specific needs, improving debugging and monitoring capabilities.

Also the default service `ConsoleLogger` can by default log messages in JSON format, making it easier to integrate with log management systems.

Learn more about the new Logger in the [Logger Documentation](../techniques/logging).

### Pipes

Pipes are a new feature in Serinus 2.0 that allows developers to transform and validate data as it flows through the application. Inspired by similar concepts in other frameworks, Pipes provide a clean and efficient way to handle data processing, ensuring that inputs and outputs meet the required criteria.

```dart
import 'package:serinus/serinus.dart';

class MyPipe extends Pipe {
  @override
  Future<void> transform(ExecutionContext context) async {
    // Transform the data here
  }
}
```

Pipes can be applied at various levels, including route handlers, controllers, and globally across the application. This flexibility allows developers to create reusable data processing logic that can be easily integrated into different parts of the application.

Learn more about Pipes in the [Pipes Documentation](../pipes/).

### Exception Filters

Exception Filters are another new feature in Serinus 2.0 that provides a structured way to handle exceptions and errors within the application. By defining custom exception filters, developers can centralize error handling logic, ensuring consistent responses and logging across the application.

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

By defining catch targets, Exception Filters can be tailored to handle specific types of exceptions, allowing for granular control over error handling behavior.

Learn more about Exception Filters in the [Exception Filters Documentation](../exception_filters/).

### Revamped Middlewares System

Serinus management of middlewares was always a bit limited, not very flexible and very often hard to use in complex scenarios. With Serinus 2.0, we have completely revamped the Middlewares system to provide a more powerful and flexible way to manage middlewares in your application.

```dart
class AppModule extends Module {
  AppModule() : super(
    imports: [
    ],
    controllers: [
      AppController(),
    ],
    providers: [],
  );

  @override
  void configure(MiddlewareConsumer consumer) {
    consumer
      .apply([AuthMiddleware()])
      .forRoutes([RouteInfo('/protected')]);
  }
}
```

Learn more about the new Middlewares system in the [Middlewares Documentation](../middlewares/).

### Server-Sent Events (SSE) Support

Serinus already supports WebSockets for real-time communication, but we wanted to provide a simpler alternative for scenarios where full-duplex communication is not required. With Serinus 2.0, we have introduced built-in support for Server-Sent Events (SSE), allowing developers to easily implement one-way real-time updates from the server to the client.

```dart
import 'package:serinus/serinus.dart';

class MySseController extends Controller with SseController {

  MySseController() : super('/sse') {
    onSse(Route.get(''))
  }
}
```

</BlogPage>