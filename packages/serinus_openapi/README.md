![Serinus Banner](https://raw.githubusercontent.com/francescovallone/serinus/main/packages/serinus/assets/github-header.png)

# Serinus OpenAPI

A plugin to add OpenAPI Specification in your Serinus applications 🐤.

## Installation

```bash
dart pub add serinus_openapi
```

## Usage

```dart
void main(List<String> args) async {
  final document = DocumentSpecification(
      title: 'Serinus Test Swagger',
      version: '1.0',
      description: 'API documentation for the Serinus project',
      license: LicenseObject(
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT',
      ),
      contact:
          ContactObject(name: 'Serinus', url: 'https://serinus.dev', email: ''))
    ..addBasicAuth();
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
  );
  final swagger = await SwaggerModule.create(app, document, components: [
    Component<SchemaObject>(
        name: 'User',
        value: SchemaObject(type: SchemaType.object, value: {
          'name': SchemaObject(),
          'age': SchemaObject(type: SchemaType.integer),
          'email': SchemaObject(),
        })),
    Component<ResponseObject>(
        name: 'SuccessResponse',
        value: ResponseObject(description: 'Success response', content: [
          MediaObject(
              schema: SchemaObject(
                  type: SchemaType.text,
                  example: SchemaValue<String>(value: 'Hello world')),
              encoding: ContentType.text)
        ])),
    Component<ParameterObject>(
        name: 'NameParam',
        value: ParameterObject(
          name: 'name',
          in_: SpecParameterType.query,
          required: false,
        )),
    Component<RequestBody>(
        name: 'DataBody',
        value: RequestBody(
          name: 'data',
          value: {
            'name': MediaObject(
                schema: SchemaObject(
                    type: SchemaType.text,
                    example: SchemaValue<String>(value: 'John Doe')),
                encoding: ContentType.json),
          },
          required: true,
        )),
  ]);
  await swagger.setup(
    '/api',
  );
  await app.serve();
}
```
