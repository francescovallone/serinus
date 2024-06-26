# Components

If you want to add Components to your OpenAPI Specification, you can do so by using the `Component` class.

This class can be used for adding:

- Schemas
- Responses
- Parameters
- Examples
- RequestBodies
- Headers
- SecuritySchemes

## Schemas

The `SchemaObject` class is used to define a schema for your OpenAPI Specification document.

### Properties

- `type` - The type of the schema. (required)
- `example` - An example of the schema.
- `value` - The value of the schema.

### Example

```dart
import 'package:serinus_swagger/serinus_swagger.dart';
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
    components: [
      Component<SchemaObject>(
        name: 'User', 
        value: SchemaObject(
          type: SchemaType.object, 
          value: {
            'name': SchemaObject(),
            'age': SchemaObject(type: SchemaType.integer),
            'email': SchemaObject(),
          }
        )
      ),
    ]
  );
  await swagger.setup(
    '/api',
    components: component,
  );
  await app.serve();
}
```

### Access the Schema Component

You can access the schema component in a ref `SchemaObject`.

```dart
SchemaObject(
  type: SchemaType.ref,
  value: 'schemas/User'
)
```

## Responses

The `ResponseObject` class is used to define a response for your OpenAPI Specification document.

### Properties

- `description` - The description of the response. (required)
- `content` - The content of the response.
- `headers` - The headers of the response.

### Example

```dart
import 'package:serinus_swagger/serinus_swagger.dart';
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
    components: [
      Component<ResponseObject>(
        name: 'SuccessResponse',
        value: ResponseObject(
          description: 'Success response',
          content: [
            MediaObject(
              schema: SchemaObject(
                type: SchemaType.text,
                example: SchemaValue<String>(value: 'Hello world')
              ),
              encoding: ContentType.text
            )
          ]
        )
      ),
    ]
  );
  await swagger.setup(
    '/api',
    components: component,
  );
  await app.serve();
}
```

### Access the Response Component

You can access the response component in a ref `ResponseObject`.

```dart
SchemaObject(
  type: SchemaType.ref,
  value: 'responses/SuccessResponse'
),
```

## Parameters

The `ParameterObject` class is used to define a parameter for your OpenAPI Specification document.

### Properties

- `name` - The name of the parameter. (required)
- `in_` - The location of the parameter. (required)
- `description` - The description of the parameter.
- `required` - Whether the parameter is required.
- `schema` - The schema of the parameter.
- `examples` - An example of the parameter.
- `deprecated` - Whether the parameter is deprecated.

### Example

```dart
import 'package:serinus_swagger/serinus_swagger.dart';
import 'package:serinus/serinus.dart';

Component<ParameterObject>(
  name: 'NameParam',
  value: ParameterObject(
    name: 'name',
    in_: SpecParameterType.query,
    required: false,
  )
)
```

### Access the Parameter Component

You can access the parameter component in a ref `ParameterObject`.

```dart
SchemaObject(
  type: SchemaType.ref,
  value: 'parameters/NameParam'
),
```

## Examples

The `ExampleObject` class is used to define an example for your OpenAPI Specification document.

### Properties

- `summary` - The summary of the example.
- `description` - The description of the example.
- `value` - The value of the example. (required)

### Example

```dart
import 'package:serinus_swagger/serinus_swagger.dart';
import 'package:serinus/serinus.dart';

Component<ExampleObject>(
  name: 'Example',
  value: ExampleObject(
    value: 'Hello world',
  )
)
```

### Access the Example Component

You can access the example component in a ref `ExampleObject`.

```dart
SchemaObject(
  type: SchemaType.ref,
  value: 'examples/Example'
),
```

## RequestBodies

The `RequestBody` class is used to define a request body for your OpenAPI Specification document.

### Properties

- `name` - The name of the request body.
- `required` - Whether the request body is required. (default: false)
- `value` - The value of the request body. (required)

### Example

```dart
import 'package:serinus_swagger/serinus_swagger.dart';
import 'package:serinus/serinus.dart';

Component<RequestBody>(
  name: 'UserBody',
  value: RequestBody(
    value: SchemaObject(
      type: SchemaType.object,
      value: {
        'name': SchemaObject(),
        'age': SchemaObject(type: SchemaType.integer),
        'email': SchemaObject(),
      }
    )
  )
)
```

### Access the RequestBody Component

You can access the request body component in a ref `RequestBody`.

```dart
SchemaObject(
  type: SchemaType.ref,
  value: 'requestBodies/UserBody'
),
```

## Headers

The `HeaderObject` class is used to define a header for your OpenAPI Specification document.

### Properties

- `name` - The name of the header. (required)
- `description` - The description of the header.
- `required` - Whether the header is required.
- `deprecated` - Whether the header is deprecated.

::: info
If the name of the header is `accept`, `content-type`, `authorization`, then the header will be ignored.
:::

### Example

```dart
import 'package:serinus_swagger/serinus_swagger.dart';
import 'package:serinus/serinus.dart';

Component<HeaderObject>(
  name: 'AuthorizationHeader',
  value: HeaderObject(
    name: 'Sec',
    description: 'Security header',
    required: true,
  )
)
```

## SecuritySchemes

The `SecurityObject` class is used to define a security scheme for your OpenAPI Specification document.

### Properties

- `type` - The type of the security scheme. (required)
- `isDefault` - Whether the security scheme is the default (Default: false)
- `scheme` - The scheme of the security scheme. (required for `http` type)
- `bearerFormat` - The bearer format of the security scheme. (required for `http` type with `bearer` scheme)
- `inType` - The location of the security scheme. (required for `apiKey` type)
- `name` - The name of the security scheme. (required for `apiKey` type)
- `flows` - The flows of the security scheme. (required for `oauth2` type)
- `openIdConnectUrl` - The OpenID Connect URL of the security scheme. (required for `openIdConnect` type)

### Example

```dart

import 'package:serinus_swagger/serinus_swagger.dart';

Component<SecurityObject>(
  name: 'BearerAuth',
  value: SecurityObject(
    type: SecurityType.http,
    scheme: 'bearer',
    bearerFormat: 'JWT',
  )
)

```
