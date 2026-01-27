# Versioning

::: info
This chapter is only relevant to HTTP-based applications.
:::

Versioning is a crucial aspect of API design. It allows you to introduce breaking changes without affecting existing clients.
Currently Serinus supports two types of versioning: **Uri** and **Header**.

| Type | Description |
|------|-------------|
| Uri | The version is specified in the URI. (default) |
| Header | The version is specified in a custom request header. |

## Uri Versioning

URI versioning uses the passed URI to specify the version of the API like `/v1/users` and `/v2/users`.

::: warning
With URI Versioning the version will be automatically added to the URI after the global prefix (if one exists), and before any controller or route paths.
:::

To enable URI versioning, you can pass a new `VersioningOptions` to the setter `versioning` in your Serinus Application instance.

```dart
import 'package:serinus/serinus.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(), host: InternetAddress.anyIPv4, port: 3000);
    app.versioning = VersioningOptions(
        type: VersioningType.uri,
    );
    await app.serve();
}
```

::: info
The version in the URI will be automatically prefixed with v by default.
:::

## Header Versioning

Header versioning uses a custom header to specify the version of the API like `X-API-Version: 1`.

To enable Header versioning, as before, you can pass a new `VersioningOptions` to the setter `versioning` in your Serinus Application instance.

```dart
import 'package:serinus/serinus.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(), host: InternetAddress.anyIPv4, port: 3000);
    app.versioning = VersioningOptions(
        type: VersioningType.header,
        header: 'X-API-Version',
    );
    await app.serve();
}
```

## Versioning in Controllers

Sometimes you may want to have different versions of the same route in different controllers. To achieve this, you can override and set the `version` getter.

```dart
import 'package:serinus/serinus.dart';

class UsersController extends Controller {
  @override
  int get version => 2;

  UsersController(): super('/users') {
    on(Route.get('/'), (RequestContext context) async {
      return 'Users';
    });
  }
}
```

In the example above, the route `/users` will be available only in version 2 of the API. If you try to access it with version 1, you will receive a 404 error.

## Versioning in Routes

You can also set the version of a route directly in the `Route` object.

::: info
Right now to achive this you need to create your custom route object and pass it to the `on` method.
:::

As before you will only need to override the `version` getter.

```dart
import 'package:serinus/serinus.dart';

class CustomRoute extends Route {
  @override
  int get version => 2;

  CustomRoute(String path) : super(path: path, method: HttpMethod.get);
}

class UsersController extends Controller {
  UsersController(): super('/users') {
    on(CustomRoute('/'), (RequestContext context) async {
      return 'Users';
    });
  }
}
```

## Ignore Versioning

Sometimes you may want a route that is not affected by versioning. To achieve this, you can augment the route or controller with the `IgnoreVersion` metadata.

```dart
import 'package:serinus/serinus.dart';

class UsersController extends Controller {
  UsersController(): super('/users') {
    on(Route.get('/', metadata: [IgnoreVersion()]), (RequestContext context) async {
      return 'Users';
    });
  }
}
```

In the example above, the route `/users` will ignore the application versioning.

The same applies to controllers:

```dart
import 'package:serinus/serinus.dart';

class UsersController extends Controller {
  UsersController(): super('/users') {
    on(Route.get('/'), (RequestContext context) async {
      return 'Users';
    });
  }

  @override
  List<Metadata> get metadata => [IgnoreVersion()];
}
```