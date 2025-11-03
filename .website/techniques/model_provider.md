# Model Provider

One of the most common part when dealing with APIs is to provide a way to interact with the data. Although a Map is a good way to represent data, it is not the best way to interact with it. But what if you could generate and use classes to interact with the data? That's what the `ModelProvider` does.

The `ModelProvider` is a special class that maps Serinus body objects to Dart classes. It is a way to generate classes that represent the data received from the API like a FormData Object or a JSON object.

::: tip
While extending the ModelProvider class yourself is a good way to have full control over the conversion process, it is recommended to use the serinus generate models command to generate a model provider class for your project.
:::

To generate a model provider in your project just execute the command below:

```bash
serinus generate models
```

## Usage

We have now generated a model provider class in the `models` directory of your project but the Serinus application is not aware of it yet. To make the application aware of the model provider, you need to pass it to the `modelProvider` parameter of the `createApplication` method.

```dart
import 'package:serinus/serinus.dart';

import 'models/model_provider.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(), host: '0.0.0.0', port: 3000, modelProvider: MyModelProvider());
  await app.serve();
}
```

Now that the application is aware of the model provider, you can use it to convert the body of the request to a Dart class.

```dart
import 'package:serinus/serinus.dart';

class User {
  final String name;
  final String email;

  User({required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(name: json['name'], email: json['email']);
  }
}

class UsersController extends Controller {
  UsersController() : super('/users') {
    on(Route.post('/'), body: User, (RequestContext context) async {
      final user = context.bodyAs<User>();
      return 'User created';
    });
  }
}

```

But wait it becomes even better! Even tho during the generation the `ModelProvider` will look up for the `fromJson` method and the `toJson` method, you can also add more methods that the `ModelProvider` will use to convert the data.

To do that you need just to add the configuration to your pubspec.yaml file.

```yaml
serinus:
  models:
    extensions:
      - test
    deserialize_keywords:
      - keyword: fromRequest
        static_method: true
    serialize_keywords:
      - keyword: toResponse
```
