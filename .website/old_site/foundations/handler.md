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

## Static Handler

A static handler is a function that does not require a `RequestContext` object. It is useful when you need to return instant responses. It uses the `onStatic` method of the `Controller` class instead of the `on` method.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    onStatic(Route.get('/'), 'Hello World!');
  }
}
```

## Typed body handler

::: tip
Before using typed body handlers, make sure to read the [Model Provider](/techniques/model_provider) section.
:::

The handler can also receive a body of a specific type. This is useful when you need to receive a JSON body and convert it to a Dart object.

```dart
import 'package:serinus/serinus.dart';

class MyObject {
  String name;

  MyObject({this.name});

  factory MyObject.fromJson(Map<String, dynamic> json) {
    return MyObject(name: json['name']);
  }
}

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/'), body: MyObject, (RequestContext context, MyObject body) async {
      return 'Hello ${body.name}!';
    });
  }
}
```

In this case, the handler will receive an instance of `MyObject` as the second parameter.

In the case of a parametric route, the body must be the second parameter after the context.

```dart
import 'package:serinus/serinus.dart';

class MyObject {
  String name;

  MyObject({this.name});

  factory MyObject.fromJson(Map<String, dynamic> json) {
    return MyObject(name: json['name']);
  }
}

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(Route.get('/<name>'), body: MyObject, (RequestContext context, MyObject body, String name) async {
      return 'Hello $name ${body.name}!';
    });
  }
}
```