# Paths

Paths are the identifiers to locate resources of a server.

<img src="/paths.png" alt="Paths" style="width: 100%;">

As explained in the image above, a path starts with a `/` and ends when the query string starts. 

To explain even further:

| Url | Path |
| --- | --- |
| `https://example.com` | `/` |
| `https://example.com/about` | `/about` |
| `https://example.com/about?name=serinus` | `/about` |

## Path Parameters

Serinus allows you to define dynamic paths by using path parameters. Path parameters are defined by the parameter name surrounded by `<` `>`.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/<id>'), (context) async {
      return 'Hello World ${context.params['id']}!';
    });
  }
}
```

In the example above, the `MyController` controller has a route that accepts a path parameter named `id`. The value of the path parameter can be accessed through the `params` property of the `RequestContext` object.

### Multiple Path Parameters

You can define multiple path parameters in a route.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/<id>/<name>'), (context) async {
      return 'Hello ${context.params['name']} with id ${context.params['id']}!';
    });
  }
}
```

In the example above, the `MyController` controller has a route that accepts two path parameters named `id` and `name`.

### Wildcard Path

You can define a wildcard path by using the `*` character.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/<id>/*'), (context) async {
      return 'Hello World ${context.params['id']}!';
    });
  }
}
```

In the example above, the `MyController` controller has a route that accepts a path parameter named `id` and a wildcard path.

| Path | Accepted |
| --- | --- |
| `/1` | Yes |
| `/1/2` | Yes |
| `/1/2/3` | Yes |

## Query Parameters

Query parameters are key-value pairs that are sent in the URL. Serinus will try to parse the query parameters to the type that you defined in the route.

```dart
import 'package:serinus/serinus.dart';

class GetRoute extends Route {
  const GetRoute({
    required super.path, 
    super.method = HttpMethod.get,
    super.queryParameters = const {
        'name': String,
    },
  });
}
```

In the example above, the `GetRoute` route has a query parameter named `name` that is a `String`.

But you are not forced to define the type of the query parameter. If you don't define the type, Serinus will parse the query parameter to a `String`.

You can access the query parameters through the `query` property of the `RequestContext` object.

