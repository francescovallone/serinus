# Swagger Plugin

A plugin to add OpenAPI Specification in your Serinus applications 🐤.

## Installation

```bash
dart pub add serinus_swagger
```

## Usage

By default the plugin will expose the OpenAPI Specification at the `/swagger` endpoint. You can customize the endpoint by passing the `endpoint` parameter to the `SwaggerPlugin` constructor.

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
