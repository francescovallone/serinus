---
title: Serinus 2.1 - Morning Song
sidebar: false
editLink: false
search: false
outline: [2, 4]
head:
    - - meta
      - property: 'og:title'
        content: Serinus 2.1 - Morning Song

    - - meta
      - name: 'description'
        content: Introducing new router, Class and Value Providers and Loxia integration.

    - - meta
      - property: 'og:description'
        content: Introducing new router, Class and Value Providers and Loxia integration.
    - - meta
      - property: 'og:image'
        content: https://serinus.app/blog/serinus_2_1/serinus_2_1.webp

    - - meta
      - property: 'twitter:image'
        content: https://serinus.app/blog/serinus_2_1/serinus_2_1.webp
---

<script setup>
    import BlogPage from '../components/blog/blog_page.vue'
</script>

<BlogPage
    title="Serinus 2.1 - Morning Song"
    src="/blog/serinus_2_1/serinus_2_1.webp"
    alt="Serinus 2.1 - Morning Song"
    author="Francesco Vallone"
    date="12 Feb 2026"
    :tags="['releases']"
    shadow
    blog
>

Serinus 2.1, named "Morning Song", focuses on enhancing the developer experience, introducing new features and improving performance. This release introduces Atlas as the new default router, Class and Value Providers for more flexible dependency injection and finally Loxia joins the ecosystem providing a flexible ORM for your applications.

## Loxia Integration

Loxia is a powerful and flexible ORM designed to work seamlessly with Serinus. With Loxia, developers can easily manage database interactions using a simple and intuitive API. With Serinus 2.1 we are excited to announce the official integration of Loxia into the Serinus ecosystem. This integration allows developers to leverage Loxia's capabilities directly within their Serinus applications, making it easier to work with databases and manage data models.

Integrating Loxia with Serinus is straightforward. Developers can define their database models as Dart classes and use Loxia's powerful features for data management while benefiting from Serinus's modular architecture and dependency injection system. This integration provides a seamless experience for developers, allowing them to focus on building their applications without worrying about the complexities of database management.

```dart
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule()
	: super(
      imports: [
        LoxiaModule.inMemory(entities: [User.entity]),
        LoxiaModule.features(entities: [User]),
      ],
		  controllers: [UserController()],
	  );
}
```

Read more about Loxia integration in the [Serinus documentation](/techniques/database.html) and check out the [serinus_loxia package](https://pub.dev/packages/serinus_loxia) for more details and examples.

## Class Providers

One of the most significant additions in Serinus 2.1 is the introduction of Class Providers. This new feature allows developers to register concrete implementation using their abstract classes in the dependency injection system, enabling more flexible and dynamic service management.

```dart
abstract class DatabaseService {
  void connect();
}

class MySQLDatabaseService implements DatabaseService {
  @override
  void connect() {
    // MySQL connection logic
  }
}

class AppModule extends Module {
  @override
  List<Provider> get providers => [
        Provider.forClass<DatabaseService>(
            useClass: MySQLDatabaseService()
        ),
    ];
}
```

## Value Providers

In addition to Class Providers, Serinus 2.1 introduces Value Providers, which allow developers to register constant values or configurations in the dependency injection system. This is particularly useful for managing application settings or environment-specific configurations, on in some cases to inject objects that were created outside the DI system.

```dart
class AppModule extends Module {
  @override
  List<Provider> get providers => [
        Provider.forValue<String>(
            useValue: 'https://api.example.com'
        ),
    ];
}
```

Value Providers can also be differentiated by using named tokens:

```dart
class AppModule extends Module {
  @override
  List<Provider> get providers => [
        Provider.forValue<String>(
            name: 'API_URL',
            useValue: 'https://api.example.com'
        ),
    ];
}
```

::: tip
We suggest using always Value Providers with named tokens to avoid conflicts when registering multiple values of the same type.
:::

## FormData and File Upload Enhancements

Serinus 2.1 introduces improved support for handling `FormData` and file uploads. The new features make it easier to work with multipart form data, this release add the `file` method to the `FormData` class, allowing developers to handle file uploads more intuitively.

```dart
class UploadController extends Controller {
  UploadController(): super('/upload') {
    on(Route.get('/form'), _upload);
  }

  Future<Map<String, dynamic>> _upload(RequestContext<FormData> context) async {
    final file = context.body.file('fileFieldName');
    // Process the uploaded file
    return {'status': 'File uploaded successfully'}
  }
}
```

## IgnoreVersion metadata

In Serinus 2.1, we have added the `IgnoreVersion` metadata that can be used to exclude specific controllers or routes from versioning. This is particularly useful for routes that should remain consistent across different API versions.

```dart
class LegacyController extends Controller {
  LegacyController(): super('/legacy') {
    on(Route.get('/data', metadata: [IgnoreVersion()]), _getData);
  }

  Future<Map<String, dynamic>> _getData(RequestContext context) async {
    return {'data': 'This route is not versioned'};
  }
}
```

## Atlas as Default Router

From the start of Serinus used Spanner as the default router, it was a great choice back in the days and still is for many use cases, but as the framework evolved we needed more flexibility and features that Spanner couldn't provide. Also we wanted to have more control over the routing system to better integrate it with the rest of the framework.

So we developed Atlas, a new router built specifically for Serinus. Atlas offers better performance, more features, and greater flexibility compared to Spanner. 
Atlas allows you to:

- Define parametric routes with both `<:param>` and `:param` syntax
- Use wildcards and tail wildcards for more flexible route matching
- Use optional parameters in routes (A first in the Dart ecosystem!)
- Improved route lookup performance

Our benchmarks show that Atlas provides better performance compared to Spanner, especially in applications with a large number of routes.

Also we would love to release Atlas as a standalone package in the future, so stay tuned for that!

## New Agents command in Serinus CLI

To enhance the experience of using Serinus documentation with AI agents, we have introduced a new `agents` command in the Serinus CLI. This command generates an `AGENTS.md` file in the root of your Serinus project and downloads the documentation locally, allowing you to use your favorite LLMs more effectively.

```bash
serinus agents
```

This changes allow us to explore the possibility to better integrate Serinus documentation with various AI agents in the future, making it easier for developers to access information and get assistance while building their applications.

## Other Changes

### Etags

I know, I know it is about time! Serinus 2.1 introduces built-in support for Etags, this will reduce bandwidth usage and improve performance for clients that support it.

### Add type-matching optimization to body parsers

We have improved the body parsers to include type-matching optimizations. This means that the framework can now more efficiently parse request bodies based on the expected type, reducing overhead and improving performance.

## Conclusion

Serinus 2.1 "Morning Song" is a significant step forward in our mission to provide a powerful and flexible framework for building server-side applications with Dart. With the introduction of Atlas, Class and Value Providers, and various performance optimizations, we believe that Serinus 2.1 will help developers create even more efficient and scalable applications.

Buuut, we are not stopping here! We have many more exciting features and improvements planned for future releases, so stay tuned for more updates.

The 2.2 release will make you *observe* 👀 some exciting new features!

</BlogPage>
