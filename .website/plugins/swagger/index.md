<script setup>
	import PluginType from '../../components/plugin_type.vue'
  import PluginButtons from '../../components/plugin_buttons.vue'
</script>

# Swagger Plugin

<PluginType :types="['Module']" />

A plugin to add OpenAPI Specification in your Serinus applications 🐤.

## Installation

```bash
dart pub add serinus_swagger
```

## Usage

The plugin will expose the OpenAPI Specification in one endpoint. You can customize the endpoint by passing the `endpoint` parameter to the `setup` method.

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_swagger/serinus_swagger.dart';

void main(List<String> args) async {
  final document = DocumentSpecification(
    title: 'Serinus Test Swagger',
    version: '1.0',
    description: 'API documentation for the Serinus project',
  );
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
  );
  final swagger = await SwaggerModule.create(
    app, 
    document,
  );
  await swagger.setup(
    '/api',
  );
  await app.serve();
}
```

## Links

<PluginButtons 
  :buttons="[
    {
      label: 'Pub.dev',
      url: 'https://pub.dev/packages/serinus_swagger',
    }
  ]" 
/>