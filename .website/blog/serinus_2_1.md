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
        content: The Serinus 2.1 release introduces Atlas, Class Providers, and more.

    - - meta
      - property: 'og:description'
        content: The Serinus 2.1 release introduces Atlas, Class Providers, and more.

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
    date="27 Jan 2026"
    :tags="['releases']"
    shadow
    blog
>

Serinus 2.1, named "Morning Song", focuses on enhancing the developer experience and improving performance. This release introduces Atlas as the new default router, Class Providers for more flexible dependency injection, and various optimizations to make your Serinus applications faster and more efficient. 

## New Features

### Class Providers

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

### FormData and File Upload Enhancements

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

### IgnoreVersion metadata

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

## Performance Improvements

One of the main focuses of Serinus 2.1 has been on performance optimization. We have made several under-the-hood improvements to enhance the speed and efficiency of Serinus applications. 
It took a while and we are still improving some parts of the framework, specifically in the next versions you could expect even more performance boosts, especially in the areas of memory management. But in this release we have already achieved significant improvements in request handling and routing speed, making Serinus applications faster and more responsive.

We focused on hot paths and optimized them to reduce latency and improve throughput achieving **~1.2x** faster request handling compared to Serinus 2.0.

::: info
**Note:** The benchmark results may vary based on the specific application and environment. We recommend running your own benchmarks to see the performance improvements in your use case.
:::

**Benchmark Results:**

| Version    | Requests per Second |
|------------|---------------------|
| Serinus 2.1| 11087,77            |
| Serinus 2.0| 9245,79             |

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

## Other Changes

### Etags

I know, I know it is about time! Serinus 2.1 introduces built-in support for Etags, this will reduce bandwidth usage and improve performance for clients that support it.

### Add type-matching optimization to body parsers

We have improved the body parsers to include type-matching optimizations. This means that the framework can now more efficiently parse request bodies based on the expected type, reducing overhead and improving performance.

## Conclusion

Serinus 2.1 "Morning Song" is a significant step forward in our mission to provide a powerful and flexible framework for building server-side applications with Dart. With the introduction of Atlas, Class Providers, and various performance optimizations, we believe that Serinus 2.1 will help developers create even more efficient and scalable applications.

Buuut, we are not stopping here! We have many more exciting features and improvements planned for future releases, so stay tuned for more updates.

The 2.2 release will make you *observe* 👀 some exciting new features!

</BlogPage>
