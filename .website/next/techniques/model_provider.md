# Model Provider

Serinus provides a way to convert JSON objects to Dart objects and vice versa.

This is done by using the `ModelProvider` class. A special class that you can either extend yourself adding the necessary methods or use the `serinus generate models` command to generate a model provider class for your project.

::: tip
While extending the `ModelProvider` class yourself is a good way to have full control over the conversion process, it is recommended to use the `serinus generate models` command to generate a model provider class for your project.
:::

## Generate a Model Provider

To generate a model provider class for your project, run the following command:

```bash
serinus generate models
```

This command will generate a `ModelProvider` class in the entry point of your project. The generated class will have the necessary methods to convert JSON objects to Dart objects and vice versa.

## Using the Model Provider

To use the newly generated `ModelProvider` class, you just need to pass it to the `SerinusApplication` class when initializing it.

```dart
import 'package:serinus/serinus.dart';
import 'my_model_provider.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(), host: '0.0.0.0', port: 3000, modelProvider: MyModelProvider());
  await app.serve();
}
```

## Options while generating a Model Provider

To read more about the options available while generating the model provider for your project you can go to the [Configuration](/next/techniques/configuration) section.