# Generate

The `generate` command is used to generate code for your Serinus project. This command is used to generate the following:

| Sub-Command | Description |
| --- | --- |
| `models` | Generate a model provider class for your project. |
| `controller` | Generate a controller class for your project. |
| `provider` | Generate a provider class for your project. |
| `module` | Generate a module class for your project |
| `resource` | Generate a controller, a provider and a module for your project |

## Models

The `models` sub-command is used to generate a model provider class for your project. This class is used to convert JSON objects to Dart objects and vice versa.

It also execute build_runner to generate the necessary files. This allows you to use libraries like `json_serializable`, `dart_mappable`, `freezed` to generate your data classes.

This commands can also be tweaked by the usage of the configuration in the `pubspec.yaml` file.
[Here](/techniques/configuration#models-configuration) is how you can configure the models generation.
