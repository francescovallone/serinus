# Router Module

::: tip
This chapter is only relevant to HTTP-based applications. Microservices do not support the Router Module.
:::

In an HTTP application (for example, REST API), the route path for a handler is determined by concatenating the prefix declared for the controller and any path specified when defining the route handler. You can learn more about that in [this section](/controllers#routing). Additionally, you can define a [global prefix](/techniques/global_prefix) for all routes in the application, or enable [versioning](/techniques/versioning) to have versioned routes.

However, there may be some edge-cases when defining a prefix at a module-level (and so for all controllers and routes declared in that module) can be useful. For example, you may want to have a module dedicated to user management, and all routes declared in that module should be prefixed with `/users`. In such cases, you can use the Router Module.

```dart
class AppModule extends Module {
  AppModule() : super(
    imports: [
      UserModule(),
      RouterModule([
        ModuleMount(
          module: UserModule,
          path: '/users',
        )
      ]),
    ],
    controllers: [],
    providers: [],
  );
}
```

## Hierarchies of Module Mounts

In addition, you can define hierarchies of module mounts, which allows you to have nested routes. For example, you may want to have a module dedicated to user management, and within that module, you may want to have a sub-module dedicated to user profiles, and all routes declared in that sub-module should be prefixed with `/users/profiles`. In such cases, you can define a hierarchy of module mounts.

```dart
class AppModule extends Module {
  AppModule() : super(
    imports: [
      UserModule(),
      UserProfileModule(),
      RouterModule([
        ModuleMount(
          module: UserModule,
          path: '/users',
          children: [
            ModuleMount(
              module: UserProfileModule,
              path: '/profiles',
            ),
          ],
        )
      ]),
    ],
    controllers: [],
    providers: [],
  );
}
```

::: tip
This feature should be used very carefully, as overusing it can make code difficult to maintain over time.
:::

In the example above, all routes declared in the `UserModule` will be prefixed with `/users`, and all routes declared in the `UserProfileModule` will be prefixed with `/users/profiles`.
