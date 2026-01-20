---
title: Serinus 1.0 - Primavera
sidebar: false
editLink: false
search: false
head:
    - - meta
      - property: 'og:title'
        content: Serinus 1.0 - Primavera

    - - meta
      - name: 'description'
        content: Introducing ModelProvider, Client Generation and Typed Body.

    - - meta
      - property: 'og:description'
        content: Introducing ModelProvider, Client Generation and Typed Body.

    - - meta
      - property: 'og:image'
        content: https://serinus.app/blog/serinus_1_0/serinus_1_0.webp

    - - meta
      - property: 'twitter:image'
        content: https://serinus.app/blog/serinus_1_0/serinus_1_0.webp
---

<script setup>
    import BlogPage from '../components/blog/blog_page.vue'
</script>

<BlogPage
    title="Serinus 1.0 - Primavera"
    src="/blog/serinus_1_0/serinus_1_0.webp"
    alt="Serinus 1.0 - Primavera"
    author="Francesco Vallone"
    date="26 Nov 2024"
    :tags="['releases']"
    shadow
    blog
>

Serinus 1.0, code name Primavera, is the first stable release of Serinus. It introduces ModelProvider, Client Generation, typed bodies and many other 
features.

## Table of Contents

[[toc]]

## What is Serinus?

Serinus is an open-source framework for building efficient and scalable backend applications powered by Dart.

## What's new in Serinus 1.0?

A lot! And when I say a lot, I mean a lot. But let's go step by step.

### ModelProvider

ModelProvider is a new feature that allows you to define your models that can be encoded and decoded from JSON.

Differently from other frameworks, Serinus doesn't enforce you to use a specific library or a specific way to define your models. You can use the one you prefer, and Serinus will take care of the rest.

And if a library doesn't use the `toJson` and `fromJson` methods? No problem you can just tweak a little the configuration in your pubspec.yaml file, and you are good to go.

Oh and if the model doesn't look for a Json body but for a form-data body? No problem, the ModelProvider can handle that too.

:::code-group

```dart[user.dart]
import 'package:serinus/serinus.dart';

class User {
  final String name;
  final String email;

  User({required this.name, required this.email});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
    );
  }
}
```

```dart[app_controller.dart]
import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController({this.path = '/app'}) {
    on(Route.post('/'), body: User, _createApp);
  }

  Future<String> _createApp(RequestContext context, User body) async {
    return 'App ${body.name} created';
  }

}
```

```dart[model_provider.dart]
import 'package:serinus/serinus.dart';

class GenModelProvider extends ModelProvider {

  @override
  Map<Type, Function> get fromJsonModels => {
    User: (json) => User.fromJson(json),
  }

  @override
  Map<Type, Function> get toJsonModels => {
    User: (model) => (model as User).toJson(),
  }

  @override
  Object from(Type model, Map<String, dynamic> json) {
    return fromJsonModels[model]!(json);
  }

  @override
  Map<String, dynamic> to<T>(T model){
    return toJsonModels[model.runtimeType]!(model);
  }

}
```

:::
  
You can find more information about ModelProvider in the [documentation](/techniques/model_provider.html).

### Client Generation

Client Generation is another new feature that allows you to generate a client for your API.

Streamline your development process making easier to interact with your API is one of the main goals of Serinus, and Client Generation is a step in that direction.

Right now the client generation is available only for Dart and will use the library [Dio](https://pub.dev/packages/dio), but we are working to make it available for other languages and libraries too.

You can find more information about Client Generation in the [documentation](/cli/generate.html#client).

### Typed Body

One of the things we wanted to improve in Serinus was the usage of the body of the request. In the previous version of Serinus, the body could just be one of the followng types:

- `String`
- `List<int>`
- `Map<String, dynamic>`
- `FormData`

From the 1.0 this problem is solved. Now you can use any type you want without worring about the serialization or deserialization of the body.

::: warning
To use a custom type as the body of the request you need to use the ModelProvider.
:::

Here is an example of how it works:

```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController({this.path = '/app'}) {
    on(Route.post('/'), body: String, _createApp);
  }

  Future<String> _createApp(RequestContext context, String body) async {
    return 'App $body created';
  }

}
```

If you want to know more about Typed Body, you can read the [documentation](/controllers.html).

### Static Routes

Another new feature is the Static Routes. Static Routes are routes that just return a static value.

This can be useful when you need to return a static value without doing any computation.

A static route can be created using the `onStatic` method in the controller.

```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController({this.path = '/app'}) {
    onStatic(Route.get('/'), 'Hello World');
  }

}
```

If you want to know more about Static Routes, you can read the [documentation](/controllers.html).

### Parametrized Handlers

Do you remember? Developer Experience is one of the main goals of Serinus, and we are always looking for ways to improve it.

One of the new features that improve the Developer Experience is the Parametrized Handlers.

What we mean by that? We mean that instead of getting the Path Parameters from the `RequestContext` you can get them directly in the handler.

```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController({this.path = '/app'}) {
    on(Route.get('/:id'), _getApp);
  }

  Future<String> _getApp(RequestContext context, String id) async {
    return 'App $id';
  }

}
```

Don't worry, you can still get them from the `RequestContext` if you prefer.

::: warning
If you use a Parametrized Handler and a Typed Body, the Typed Body will be the first parameter after the RequestContext.
:::

If you want to know more about Parametrized Handlers, you can read the [documentation](/controllers.html).

### More lifecycle hooks

In Serinus 1.0 we added more lifecycle hooks to the application.

Now you can use two new lifecycle hooks `OnApplicationBootstrap` and `OnApplicationReady`.

The first one will be called after the application is created and before the server is started, while the second one will be called after the server is started.

```dart
import 'package:serinus/serinus.dart';

class HelloProvider extends Provider with OnApplicationBootstrap, OnApplicationReady {
  
  @override
  Future<void> onApplicationBootstrap() async {
    print('Application is bootstrapping');
  }

  @override
  Future<void> onApplicationReady() async {
    print('Application is ready');
  }
  
}
```

You can read more about Lifecycle Hooks in the [documentation](/providers.html).

### Simplified access to application configuration

In Serinus 1.0 we simplified the global prefix.

Now you can set the global prefix using the `globalPrefix` setter in your application.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    host: '0.0.0.0',
    port: 3000
  );
  app.setGlobalPrefix('/api'); // [!code --]
  app.globalPrefix = '/api'; // [!code ++]

  await app.serve();
}
```

We also simplified the view engine configuration.

Now you can set the view engine using the `viewEngine` setter in your application.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    host: '0.0.0.0',
    port: 3000
  );
  app.useViewEngine(MyViewEngine()); // [!code --]
  app.viewEngine = MyViewEngine(); // [!code ++]

  await app.serve();
}
```

And also the versioning configuration.

Now you can set the versioning using the `versioning` setter in your application.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    host: '0.0.0.0',
    port: 3000
  );
  app.enableVersioning(type: VersioningType.uri); // [!code --]
  app.versioning = VersioningOptions(type: VersioningType.uri); // [!code ++]
  await app.serve();
}
```

### Framework Configuration

If you have ever created a Serinus project using the CLI, you may have noticed a file called `config.yaml`. This file was used until the 1.0 to configure your application.

In the 1.0 we decided to remove it and use the `pubspec.yaml` file to configure your application.

This will make it easier to manage the configuration of your application and will make it easier to share your configuration with others.

### Logger Prefix

In the 1.0 you can set a prefix for the logger.

This will allow you to have a more readable log and to identify the log of your application.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    host: '0.0.0.0',
    port: 3000
  );
  app.loggerPrefix = 'MyApp';
  await app.serve();
}

```

## Breaking Changes

Serinus 1.0 is a major release and comes with some breaking changes. (Sorry for that!)

### Hooks Mixins and Hooks Service

One of the breaking changes in Serinus 1.0 are the Hooks Mixins.

Hooks are always (since 0.4.0) been a part of Serinus, but in the 1.0 we decided to make them more flexible.

Now you can decide which hooks methods you want to use instead of having all of them set as an empty method.

This will also allow you to be more explicit in your code.

```dart
import 'package:serinus/serinus.dart';

class HelloHook extends Hook with OnBeforeHandle, OnAfterHandle {
  
  @override
  Future<void> onBeforeHandle(RequestContext context) async {
    print('Hello');
  }

  @override
  Future<void> onAfterHandle(RequestContext context, dynamic response) async {
    print('Bye');
  }
  
}
```

Also hooks can now expose a service that will behave like a global provider.

```dart
import 'package:serinus/serinus.dart';

class HelloHook extends Hook with OnBeforeHandle, OnAfterHandle {
  
  @override
  Future<void> onBeforeHandle(RequestContext context) async {
    print('Hello');
  }

  @override
  Future<void> onAfterHandle(RequestContext context, dynamic response) async {
    print('Bye');
  }

  @override
  String get service => 'hello';
  
}
```

You can call it in your handlers like you would do with a provider.

```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController({this.path = '/app'}) {
    on(Route.get('/'), _getApp);
  }

  Future<String> _getApp(RequestContext context) async {
    final hello = context.use<String>();
    return 'App $hello';
  }

}
```

You can read more about Hooks in the [documentation](/hooks.html).

### Next Function in Middlewares

Another breaking change is the `next` function in the middlewares.

In the previous version of Serinus, the `next` function was a `Future<void>` function that you had to call to pass the request to the next middleware but could not emit a response.

To close the response you had to manually add the response data, header and status code to the `InternalResponse` object.

In the 1.0 we changed this behavior. Now the `next` function can take an object and returns a `Future<void>`.

If you pass an object to the `next` function, the object will be used as the response of the request will be closed.

```dart
import 'package:serinus/serinus.dart';

class HelloMiddleware extends Middleware {
  
  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    // The request will be closed with the response 'Hello'
    return next({'id': 'json-obj'});
  }
  
}
```

You can read more about Middlewares in the [documentation](/middlewares.html).

### Request Events

In the previous version of Serinus, in the middlewares was possible to listen to `ResponseEvents` but this interface was very limited and not very flexible.

In the 1.0 we decided to remove the `ResponseEvents` and introduce the `RequestEvents`.

`RequestEvents` are more explicit and flexible than the `ResponseEvents` and will also provide you with a `EventData` object containing the information that you need.

```dart
import 'package:serinus/serinus.dart';

class HelloMiddleware extends Middleware {
  
  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    context.on(RequestEvents.data, (event, data) {
      print('Data received: $data');
    });

    return next();
  }
  
}
```

You can read more about Request Events in the [documentation](/techniques/request_events.html).

### Improved Dependency Injection

In the 1.0 we improved the Dependency Injection system. In the previous versions to access the dependencies of needed for a provider you had to use the `ApplicationContext` object. And while this was working, it was not very straightforward and could lead to some confusion.

In the 1.0 we decided to change this behavior. Now you can access the dependencies directly in the provider.

::: code-group

```dart[providers.dart]
import 'package:serinus/serinus.dart';

```dart
import 'package:serinus/serinus.dart';

class ByeProvider extends Provider {
  
  void sayBye() {
    print('Bye');
  }
  
}


class HelloProvider extends Provider {
  
  final ByeProvider hello;

  HelloProvider({required this.bye});

  void sayHello() {
    print('Hello');
  }
  
}
```
  
```dart[module.dart]
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  
  AppModule() : super(providers: [
    Provider.deferred(
      (ByeProvider bye) => HelloProvider(bye: bye),
      inject: [ByeProvider], 
      type: HelloProvider
    ),
    ByeProvider(),
  ]);
  
}
```

:::

You can read more about how deferred providers work in the [documentation](/providers.html).

## Conclusion

Serinus 1.0 is a major release that brings a lot of new features and improvements. We are very excited about this release and we hope you are too. We are looking forward to seeing what you will build with Serinus 1.0 and we can't wait to hear your feedback.

Also, while the release has been tested thoroughly, there may be some bugs that we missed. If you find any bugs or have any suggestions, please let us know by opening an issue on our [GitHub repository](https:://github.com/francescovallone/serinus).

</BlogPage>
