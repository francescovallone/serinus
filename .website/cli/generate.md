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

### Configuration

To configure the `models` command, you need to add the following configuration to your `pubspec.yaml` file:

```yaml
serinus:
  models:
    extensions: 
      - "t"
    deserialize_keywords:
      - keyword: "fromRequest"
        static_method: true
    serialize_keywords:
      - keyword: "toBody"
```

In this configuration, you can specify the following options:

| Option | Description |
| --- | --- |
| `extensions` | A list of file extensions to be considered when generating models. |
| `deserialize_keywords` | A list of keywords to be used when deserializing JSON objects to Dart objects. |
| `serialize_keywords` | A list of keywords to be used when serializing Dart objects to JSON objects. |

The `deserialize_keywords` and `serialize_keywords` options are used to specify the keywords that will be used to identify the methods that will be used for deserialization and serialization respectively. The `keyword` field is used to specify the keyword that will be used to identify the method, while the `static_method` field is used to specify whether the method is a static method or not.
