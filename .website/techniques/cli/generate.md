# Generate

The `generate` command is used to generate code for your Serinus project. This command is used to generate the following:

| Sub-Command | Description |
| --- | --- |
| `models` | Generate a model provider class for your project. |
| `controller` | Generate a controller class for your project. |
| `provider` | Generate a provider class for your project. |
| `module` | Generate a module class for your project |
| `resource` | Generate a controller, a provider and a module for your project |
| `client` | Generate a client for your project |

## Models

The `models` sub-command is used to generate a model provider class for your project. This class is used to convert JSON objects to Dart objects and vice versa.

It also execute build_runner to generate the necessary files. This allows you to use libraries like `json_serializable`, `dart_mappable`, `freezed` to generate your data classes.

This commands can also be tweaked thanks to the configuration in the `pubspec.yaml` file.
[Here](/techniques/configuration#models-configuration) you can see the available options.

## Client

The `client` sub-command is used to generate a client for your project.
The client provide an immediate way to interact with your API from your frontend application.

Right now the client supports the following languages and libraries:

| Language | Library |
| --- | --- |
| Dart | `http` |
| Dart | `dio` |
| Dart | `chopper` |

This commands can also be tweaked thanks to the configuration in the `pubspec.yaml` file.
[Here](/techniques/configuration#client-configuration) you can see the available options.
