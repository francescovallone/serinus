# Handler

The handler is a function that receives a `RequestContext` object, possibly a list of parameters, and returns an object.

The handler is responsible for processing the request and returning a response.

## Creating a Handler

An handler can be defined in the following ways. You can either use an anonymous function or a named function with just one parameter of type `RequestContext`.

::: code-group

```dart [Anonymous Function (Context)]
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/'), (context) async {
      return 'Hello World!';
    });
  }
}
```

```dart [Named Function (Context)]
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/'), _helloWorld);
  }

  Future<String> _helloWorld(RequestContext context) async {
    return 'Hello World!';
  }
}
```

:::

Or you can use a named function with the `RequestContext` and the list of parameters in case of parametric routes.

::: code-group

```dart [Anonymous Function (Context, Parameters)]
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/<name>'), (RequestContext context, String name) async {
      return 'Hello $name!';
    });
  }
}
```

```dart [Named Function (Context, Parameters)]
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/<name>'), _helloWorld);
  }

  Future<String> _helloWorld(RequestContext context, String name) async {
    return 'Hello World $name!';
  }
}
```

:::

In the case of a parametric route, the handler must have the same number of parameters as the number of parameters in the route and they must follow the _**same order**_.