# Metadata

To specialize a controller or a route, you can add metadata to it. Metadata is a way to add extra information.

## Creating Metadata

Metadata can be created by extending the `Metadata` class.

```dart
import 'package:serinus/serinus.dart';

class IsPublic extends Metadata {

  const IsPublic(): super(
    name: 'IsPublic',
    value: true
  );
  
}
```

If the metadata value will be set when a request is received then you can create a ContextualizedMetadata.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {

  MyController({super.path = '/'});

  @override
  List<Metadata> get metadata => [
    ContextualizedMetadata(
      name: 'IsPublic',
      value: (context) async => context.request.headers['authorization'] == null,
    )
  ];

}
```

In the example above, the `IsPublic` metadata will be set to `true` if the `authorization` header is not present in the request.

## Add Metadata to a Controller

To add metadata to a controller, you must override the `metadata` getter.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {

  MyController({super.path = '/'});

  @override
  List<Metadata> get metadata => [IsPublic()];

}
```

## Add Metadata to a Route

To add metadata to a you can either use the factory constructors and add it to the `metadata` parameters.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {

  MyController({super.path = '/'}) {
    on(Route.get('/', metadata: [IsPublic()]), (context) async {
      return 'Hello World!';
    });
  }

}
```

Or you can extend the `Route` class and pass the metadata to the super constructor.

```dart
import 'package:serinus/serinus.dart';

class GetRoute extends Route {

  const GetRoute({
    required super.path, 
    super.method = HttpMethod.get,
  });

  @override
  List<Metadata> get metadata => [IsPublic()];

}
```

## Accessing Metadata

As explained in the [Request Context](/next/foundations/request_context.html) section, you can access the metadata from the `RequestContext` object.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {

  MyController({super.path = '/'}) {
    on(Route.get('/', metadata: [IsPublic()]), (context) async {
      if (context.stat('IsPublic')) {
        return 'Hello World!';
      } else {
        return 'You are not authorized to access this route.';
      }
    });
  }

}
```

In the example above, the `stat` method is used to access the metadata. The `stat` method receives the name of the metadata and returns the value of it. If the metadata is not found, the method will throw a `StateError`.

To prevent the `stat` method from throwing an error, you can use the `canStat` method. The `canStat` method will return `true` if the metadata is found and `false` if it is not.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {

  MyController({super.path = '/'}) {
    on(Route.get('/', metadata: [IsPublic()]), (context) async {
      if (context.canStat('IsPublic') && context.stat('IsPublic')) {
        return 'Hello World!';
      } else {
        return 'You are not authorized to access this route.';
      }
    });
  }

}
```
