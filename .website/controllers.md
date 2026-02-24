<script setup>
	import ControllerImage from './components/controllers.vue'
</script>

# Controllers

Controllers are responsible for handling incoming requests and returning responses to the client. They are the glue between the HTTP layer and the business logic of your application.

<ControllerImage />

A controller's purpose is to handle a specific set of routes for a specific part of your application. For example, you might have a `UserController` that handles all the routes for user management.

To create a controller, you need to extend the `Controller` class and define the routes you want in its controller using the `on` or the `onStatic` methods.

::: tip
To quickly scaffold a controller, you can use the `serinus generate controller` command.
:::

## Routing

Controllers define routes using the `on` and `onStatic` methods. The `on` method is used to define common routes that need access to the `RequestContext` object, while the `onStatic` method is used to define routes that will directly return a response without any further processing.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super('/users') {
    on(Route.get('/'), getUsers);
  }

  Future<List<User>> getUsers(RequestContext context) async {
    // Get all users
  }

}
```

The `Route.get` constructor is used to define a route that listens for `GET` requests. This tells Serinus to call the `getUsers` method when a `GET` request is made to `/users`. Why is that? Because the Controller will listen to the path `/users` and since the `Route.get` method is called with the path `/`, the final path will be `/users/`. In other words, we have defined in the UserController a prefix path `/users` and a route `/` that will be appended to the prefix path.

## Request Context

The `RequestContext` object is passed to the controller's methods when a route is matched. This object contains information about the current request, such as the request's headers, query parameters, path parameters and body.

It also contains a reference to the `Request` object, which is the read-only version of the request object from the HTTP server.

```dart
Future<List<User>> getUsers(RequestContext context) async {
  final users = await context.use<UsersService>().getUsers();
  return users;
}
```

The `RequestContext` object is also used to access all the providers in the module scope and all the metadata of the controller and the route. In the example above, we are using the `UsersService` provider to get all the users.

| Property | Description |
| -------- | ----------- |
| `request` | The `Request` object of the current request. |
| `body` | The body of the current request. |
| `bodyAs` | The method to parse the body as a specific type. |
| `path` | The path of the current request. |
| `headers` | The headers of the current request. |
| `params` | The path parameters of the current request. |
| `paramAs` | The method to parse a path parameter as a specific type. |
| `query` | The query parameters of the current request. |
| `queryAs` | The method to parse a query parameter as a specific type. |
| `metadata` | The metadata of the current request. |
| `res` | The `ResponseContext` of the current request. |
| `stream` | The method to stream data to the response. |
| `stat` | The method to retrieve a metadata from the context. |
| `canStat` | The method to check if a metadata exists in the context. |
| `providers` | The providers of the current module. |
| `use` | The method to get a provider from the module scope. |
| `canUse` | The method to check if a provider exists in the module scope. |

Also this object exposes two operators to access the user-defined data in the request:

- `[]` to get a value from the request metadata.
- `[]=` to set a value in the request metadata.

Here is an example of how to set a user object in the request metadata:

```dart
context['user'] = user;
```

## Wildcards

You can use wildcards in the path of a route to match any value. Wildcards are defined using the `*` character.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super('/users') {
    on(Route.get('/'), getUsers);
    on(Route.get('/*'), getUser);
  }

  Future<String> getUser(RequestContext context) async {
    return 'Wildcard';
  }

  Future<User> getUsers(RequestContext context) async {
    final user = await context.use<UsersService>().createUser(context.body);
    return user;
  }
}
```

The route `/users/*` will match any path that starts with `/users/` and will match routes like `/users/1`, `/users/2`, `/users/3`, etc.

## Tail Wildcards

Basic wildcards match only a single segment of the path. If you want to match multiple segments, but only at the end of the path, you can use tail wildcards. Tail wildcards are defined using the `**` characters.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super('/files') {
    on(Route.get('/**'), getFile);
  }

  Future<String> getFile(RequestContext context) async {
    return 'Tail Wildcard';
  }
}
```

## Status Codes

You can change the status code of the response by setting the `res.statusCode` property of the `RequestContext` object.

```dart
Future<Map<String, dynamic>> customError(RequestContext context) async {
  context.res.statusCode = 400;
  return {
    'error': 'Bad Request',
  };
}
```

::: info
If you wish to return an error status code, you should throw an exception. Serinus will catch the [exception](/exception_filters) and return the appropriate status code.
:::

## Response Headers

You can set response headers from a controller method by setting the `res.headers` property of the `RequestContext` object.

```dart
Future<User> getUser(RequestContext context) async {
  final id = context.params['id'];
  final user = await context.use<UsersService>().getUser(id);
  context.res.headers['X-Custom-Header'] = 'Custom Value';
  return user;
}
```

## Redirects

You can redirect the client to another URL by returning a `Redirect` object as the response.

```dart
Future<Redirect> redirect(RequestContext context) async {
  return Redirect('/users');
}
```

## Typed Request Body

### Decide the type beforehand

One of the most common use cases is to define the type of the request body beforehand in the method signature. Serinus will automatically parse the body of the request and return an instance of the specified type.

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

As you can see in the example above, we have defined the type of the request body as `UserCreate` in the method signature. Serinus will automatically parse the body of the request and return an instance of `UserCreate` as the `body` property of the `RequestContext` object and will expect the return type to be `User`.

::: warning
When using custom objects as request body types, make sure to register a `ModelProvider` that can handle the serialization and deserialization of your models.
:::

> [!IMPORTANT]
> Right now Serinus supports only `List<dynamic>` and `List<Map<String, dynamic>>` as request body types for lists. Support for custom object lists will be added in future releases. The reason behind this limitation is that Dart's type system does not support generic type parameters at runtime, making it impossible to determine the type of the objects in the list.

### Parse the body in the handler

You can define the type of the request body by using the `bodyAs<T>()` method of the `RequestContext` object. This method will parse the body of the request and return an instance of the specified type.
If you expect a list of objects, you can use the `bodyAsList<T>()` method instead this is a workaround until Serinus supports custom object lists as request body types.

If you have defined the `ModelProvider` to handle the serialization and deserialization of your models, you can use this method to get the body as an instance of your model. 

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super('/users') {
    on(Route.post('/'), createUser);
  }

  Future<User> createUser(RequestContext context) async {
    final body = context.bodyAs<UserCreate>();
    final newUser = await context.use<UsersService>().createUser(body);
    return newUser;
  }

  Future<List<User>> createBatchUsers(RequestContext context) async {
    final body = context.bodyAsList<UserCreate>(); // List<UserCreate>
    final newUsers = await context.use<UsersService>().createBatchUsers(body);
    return newUsers;
  }
}
```

::: info
Although both approaches are valid, using the first approach (defining the type in the method signature) is generally preferred as it provides better type safety and makes the code more readable.
:::

## Path Parameters

You can define path parameters in the route path by enclosing the parameter name in angle brackets.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super('/users') {
    on(Route.get('/<id>'), getUser);
  }

  Future<User> getUser(RequestContext context) async {
    final id = context.paramAs<String>('id');
    final user = await context.use<UsersService>().getUser(id);
    return user;
  }
}
```

Also since the integration of Atlas as the default Router in Serinus, you can define the path parameters as follow:

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super('/users') {
    on(Route.get('/:id'), getUser);
  }

  Future<User> getUser(RequestContext context) async {
    final id = context.paramAs<String>('id');
    final user = await context.use<UsersService>().getUser(id);
    return user;
  }
}
```

::: warning
The path parameters cannot be used inside the `Controller` path.
:::



## Query Parameters

You can access query parameters in the route path by using the `query` property of the `RequestContext` object.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super('/users') {
    on(Route.get('/'), getUsers);
  }

  Future<List<User>> getUsers(RequestContext context) async {
    final limit = context.query['limit'];
    final users = await context.use<UsersService>().getUsers(limit);
    return users;
  }
}
```

## Metadata

You can add metadata to your controllers by overriding the `metadata` getter.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  @override
  List<Metadata> get metadata => [
    GuardMetadata(),
  ];

  UserController(): super('/users') {
    on(Route.get('/'), getUsers);
  }

}
```

If you want to know more about metadata, please refer to the [metadata](/metadata) page.

## Static Routes

You can define static routes using the `onStatic` method. Static routes are routes that don't need access to the `RequestContext` object and that usually return a response directly.

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super('/users') {
    onStatic(Route.get('/'), 'Hello World');
  }

}
```

As you can see the `onStatic` method takes the same parameters as the `on` method, but the handler **is** the value that will be sent to the client.