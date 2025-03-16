# Controllers

Controllers are responsible for handling incoming requests and returning responses to the client. They are the glue between the HTTP layer and the business logic of your application.

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
  UserController(): super(path: '/users') {
    on(Route.get('/'), getUsers);
  }

  Future<List<User>> getUsers(RequestContext context) async {
    // Get all users
  }

}
```

The `Route.get` constructor is used to define a route that listens for `GET` requests. This tells Serinus to call the `getUsers` method when a `GET` request is made to `/users`. Why is that? Because the Controller will listen to the path `/users` and since the `Route.get` method is called with the path `/`, the final path will be `/users/`. In other words, we have defined in the UserController a prefix path `/users` and a route `/` that will be appended to the prefix path.