<script setup>
  import MetadataImage from './components/metadata.vue'
</script>

# Metadata

Metadata are used to add information to a class, a method, a property, or a parameter. In other programming languages they are easily accessible thanks to reflaction. But since they are really useful, Serinus provides his own way to add metadata to your routes and controllers.

<MetadataImage />

::: info
Dart does not support reflection, so Serinus provides a more static way to add metadata to your classes.
:::

## Creating Metadata

To create a metadata, you need to extend the `Metadata` class. As simple as that.

```dart
import 'package:serinus/serinus.dart';

class IsPublic extends Metadata {

  const IsPublic(): super(
    name: 'IsPublic',
    value: true
  );
  
}
```

As you can see, the `Metadata` class requires a `name` and a `value` parameter. The `name` is the name of the metadata, and the `value` is the value of the metadata. You can use any type of value you want.

Also, since Serinus uses a `Context` to store the request information, you can access it using a ContextualizedMetadata.

```dart
import 'package:serinus/serinus.dart';

class IsPublic extends ContextualizedMetadata {

  const IsPublic(): super(
    name: 'IsPublic',
    value: (context) async => context.query['public'] == 'true'
  );
  
}
```

In this case, the `value` is a function that returns a `Future<bool>`. This is useful when you need to access the `RequestContext` to get some information.

## Using Metadata

Now we can use the metadata in our controllers or routes.

If you add a metadata to a controller, it will be applied to all the routes of the controller. If you add a metadata to a route, it will be applied only to that specific route. Pretty cool, right?

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super('/users') {
    on(Route.get('/'), getUsers, metadata: [IsPublic()]);
    on(Route.get('/<id>'), getUser);
  }

  Future<List<User>> getUsers(RequestContext context) async {
    final users = await context.use<UsersService>().getUsers();
    return users;
  }
}
```

In this case, the `IsPublic` metadata will be applied only to the `/users` route. This means that if we have an Hook or a Middleware that checks if the user is authenticated, we can skip it for this route.

## Accessing Metadata

How we can access the metadata? It's really simple.

You can access them using two methods in the `RequestContext` object: `stat` and `canStat`.

The first one will return the metadata if it's present, otherwise it will throw a StateError. The second one will only return if the metadata is present or not.
They can be used in combination in this way:

```dart
import 'package:serinus/serinus.dart';

class UserController extends Controller {
  UserController(): super('/users') {
    on(Route.get('/'), getUsers, metadata: [IsPublic()]);
    on(Route.get('/<id>'), getUser);
  }

  Future<List<User>> getUsers(RequestContext context) async {
    if (context.canStat('IsPublic')) {
      // Do something
    }
    final users = await context.use<UsersService>().getUsers();
    return users;
  }
}
```

In this case, we check if the `IsPublic` metadata is present in the route. If it is, we can do something special. Otherwise, we can continue with the normal flow.
