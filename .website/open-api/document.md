# Document Specification

The `DocumentSpecification` class is used to define the OpenAPI Specification document for your application.

## Properties

- `title` - The title of the OpenAPI Specification document. (required)
- `version` - The version of the OpenAPI Specification document. (required)
- `description` - The description of the OpenAPI Specification document.
- `termsOfService` - The terms of service for the OpenAPI Specification document.
- `contact` - A [ContactObject](#contact-object) for the OpenAPI Specification document.
- `license` - A [LicenseObject](#license-object) for the OpenAPI Specification document.

### Contact Object

The `ContactObject` class is used to define the contact information for the OpenAPI Specification document.

#### Properties

- `name` - The name of the contact.
- `url` - The URL of the contact.
- `email` - The email of the contact. Must be a valid email address.

### License Object

The `LicenseObject` class is used to define the license information for the OpenAPI Specification document.

#### Properties

- `name` - The name of the license. (required)
- `url` - The URL of the license.

## Example

```dart
import 'package:serinus_openapi/serinus_openapi.dart';
import 'package:serinus/serinus.dart';

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
