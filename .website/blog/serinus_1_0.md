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
    import BlogPage from '../components/blog_page.vue'
</script>

<BlogPage
    title="Serinus 1.0 - Primavera"
    src="/blog/serinus_1_0/serinus_1_0.webp"
    alt="Serinus 1.0 - Primavera"
    author="Francesco Vallone"
    date="18 Nov 2024"
    shadow
>

Serinus 1.0, code name Primavera, is the first stable release of Serinus. It introduces ModelProvider, Client Generation, typed bodies and many other features.

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

You can find more information about Client Generation in the [documentation](/techniques/client_generation.html).

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

### Static Routes

Another new feature is the Static Routes. Static Routes are routes that just return a static value.

This can be useful when you need to return a static value without doing any computation.



```dart
import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController({this.path = '/app'}) {
    on(Route.get('/'), _getApp);
  }

  Future<String> _getApp(RequestContext context) async {
    return 'App';
  }

}
```

</BlogPage>
