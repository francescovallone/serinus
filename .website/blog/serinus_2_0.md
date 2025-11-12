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
    date="05 Nov 2025"
    :tags="['releases']"
    shadow
>

Serinus 2.0, named "Dawn Chorus," marks a significant milestone in our journey to provide a robust and flexible framework for building scalable server-side applications with Dart. But I like to think of it like a stepping stone towards something even greater. With this release, we have laid the groundwork for a more modular and adaptable framework that can evolve with the ever-changing landscape of web development.

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
          final config = context.use<ConfigService>();
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

With these changes, we believe that calling the plugin `serinus_swagger` is no longer appropriate, as it now supports multiple renderers and a more comprehensive OpenAPI integration. Therefore, we have renamed the package to `serinus_openapi` to better reflect its capabilities.

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

Learn more about Server-Sent Events in the [SSE Documentation](../sse/).

### Microservices

Microservices are now first-class citizens in Serinus 2.0 (finally!).
To be honest they were in the roadmap since the very beginning but the implementation took longer than expected. With Serinus 2.0, we are excited to introduce a robust microservices system that allows developers to build scalable and distributed applications with ease.

Currently it supports TCP and gRPC transport layers, with plans to add more in the future. (like MQTT, NATS and RabbitMQ)

::: warning EXPERIMENTAL
The microservices package is still experimental and may undergo significant changes in future releases. We encourage developers to try it out and provide feedback to help us improve it.
:::

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_microservices/serinus_microservices.dart';

Future<void> main() async {
  final application = await serinus.createMicroservice(
    entrypoint: AppModule(),
    transport: GrpcTransport(
      GrpcOptions(
        port: 50051,
        host: InternetAddress.loopbackIPv4,
        services: [
          GreeterService(),
        ],
      ),
    ),
  );
  await application.serve();
}
```

Learn more about Microservices in the [Microservices Documentation](../microservices/).

### Testing Utilities

Serinus 2.0 introduces a set of testing utilities that make it easier to write unit and integration tests for Serinus applications. These utilities provide helpers for simulating HTTP requests. Making really easy to create [Smoke Tests](https://en.wikipedia.org/wiki/Smoke_testing_(software)) for your application.

::: warning EXPERIMENTAL
The testing package is still experimental and may undergo significant changes in future releases. We encourage developers to try it out and provide feedback to help us improve it.
:::

```dart
import 'package:serinus_test/serinus_test.dart';

void main() {
  test('GET /users', () async {
    final application = await serinus.createTestApplication(
      entrypoint: AppModule(),
      host: InternetAddress.anyIPv4.address,
      port: 3002,
      logger: ConsoleLogger(
        prefix: 'Serinus Test Logger',
      ),
    );
    await application.serve();
    final res = await application.get('/users');
    res.expectStatusCode(200);
    res.expectJsonBody([
      {'id': 1, 'name': 'John Doe'},
      {'id': 2, 'name': 'Jane Smith'},
    ]);
  });
}
```

Learn more about Testing in the [Testing Documentation](../recipes/testing).

### Staticly Typed Handlers

Serinus 2.0 introduces strictly typed handlers, allowing developers to define the types of request bodies and responses directly in the handler method signatures. This feature enhances type safety and improves the developer experience by providing better autocompletion and error checking.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super('/users') {
    on<User, UserCreate>(Route.post('/'), createUser);
  }

  Future<User> createUser(RequestContext<UserCreate> context) async {
    final newUser = await context.use<UsersService>().createUser(context.body);
    return newUser;
  }
}
```

This feature simplifies the process of handling request and response data, making it easier to work with complex data structures.

### Execution Context

In addition to all these new features you might have seen that pipes, exception filters, middlewares and hooks have changed their APIs, using a more consistent approach based on the `ExecutionContext`.

The reason behind this change is to provide a unified and expandable way to access request and application data across different components and across different layers of the application. The `ExecutionContext` serves as a central point for accessing request information, response manipulation, and other contextual data.

What does this mean for you? Well, for starters if you were using any of these features you will need to update your code to use the new `ExecutionContext` API. But don't worry, we have provided [detailed documentation](/next/breaking-changes.html#_14-hooks-pipes-and-middlewares-now-use-the-executioncontext) to help you through the process.

## Internal Improvements

Serinus 2.0 also includes numerous internal improvements and optimizations that enhance the overall performance and stability of the framework. The most important improvements include:

- Improved dependency injection system for better performance and flexibility.
- Strictly typed handlers and routes for enhanced type safety and developer experience.
- Enhanced module system for better modularity and reusability.

## Breaking Changes

With the introduction of Serinus 2.0, there are several breaking changes that developers need to be aware of when upgrading their applications. These changes are necessary to accommodate the new features and improvements introduced in this release.

All the breaking changes are documented in the [Breaking Changes](../next/breaking-changes) documentation page.

## Other news

Oh, before I forget, Globe has released a tutorial on how to deploy Serinus applications using their platform. You can check it out [here](https://docs.globe.dev/guides/serinus-backend-globe). Thank you Globe for the support and for believing in Serinus! 💙🐤

## Conclusion

There is so much more to Serinus 2.0 than what we could cover in this blog post. We encourage you to explore the [official documentation](https://serinus.app/docs/) to learn more about the new features and improvements in detail.

But what does this mean for you as a developer? It means that you can now build applications that are more resilient, easier to maintain, and better suited to the needs of modern web development. Whether you're building a small API or a large-scale microservices architecture, Serinus 2.0 provides the tools and features you need to succeed.

And for us, this is just the beginning. We are committed to continuing to improve and evolve Serinus, and we can't wait to see what you build with it.

Happy coding! 🐤💙

</BlogPage>
