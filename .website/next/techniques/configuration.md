# Configuration

Serinus applications can be tweaked by changing the `pubspec.yaml` file. 

## Serinus Configuration

The Serinus configuration is done by adding a `serinus` key to the `pubspec.yaml` file. This key can have the following options:

| Option | Description | Default |
| --- | --- | --- |
| `models` | The configuration for the models generation | `{}` |

### Models Configuration

The `models` key can have the following options:

| Option | Description | Default |
| --- | --- | --- |
| `extensions` | The extensions used by the code generation libraries for example `g` | `[]` |
| `deserialize_keywords` | The keywords used to deserialize the JSON objects | `[]` |
| `serialize_keywords` | The keywords used to serialize the Dart objects | `[]` |

The `deserialize_keywords` and `serialize_keywords` keys can have the following options:

| Option | Description | Default |
| --- | --- | --- |
| `keyword` | The keyword to be used | |
| `static_method` | If the keyword is a static method (only for `deserialize_keywords`) | `false` |

The following is an example of the Serinus configuration:

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
