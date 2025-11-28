# Introduction

The OpenAPI Specification (OAS) is a standard for defining RESTful APIs. It allows developers to describe the structure of their APIs in a machine-readable format, which can be used to generate documentation, client libraries, and server stubs.

Serinus provides a dedicated module which allows you to automatically generate an OpenAPI specification for your application based on the defined controllers and routes.

## Installation

To install the OpenAPI module, execute the following command:

```bash
dart pub add serinus_openapi
```

## Usage

Once the module is installed, you can import it and add it to your entrypoint module.

```dart
import 'package:serinus_openapi/serinus_openapi.dart';
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [
      OpenApiModule.v3(
        InfoObject(
          title: 'Serinus OpenAPI Example',
          version: '1.0.0',
          description: 'An example of Serinus with OpenAPI integration',
        ),
      )
    ],
    controllers: [
      AppController(),
    ],
    providers: [],
  );
}
```

As you can see we are using a factory constructor called `v3` to create an OpenAPI 3 specification. You can provide an `InfoObject` which contains metadata about your API.

Doing this will generate a **minimal** OpenAPI specification. To generate a more complete specification, you can enable the analysis of your controllers and routes by setting the `analyze` parameter to `true`.

```dart
OpenApiModule.v3(
  InfoObject(
    title: 'Serinus OpenAPI Example',
    version: '1.0.0',
    description: 'An example of Serinus with OpenAPI integration',
  ),
  analyze: true,
)
```

This will analyze your controllers and routes to generate a more complete OpenAPI specification, including paths, parameters, request bodies, and responses.

## Changing the Specification Path

By default, the OpenAPI specification file is saved in the current working directory. You can change this by providing a custom path using the `specFileSavePath` parameter.

```dart
OpenApiModule.v3(
  InfoObject(
    title: 'Serinus OpenAPI Example',
    version: '1.0.0',
    description: 'An example of Serinus with OpenAPI integration',
  ),
  analyze: true,
  specFileSavePath: 'openapi_spec/',
)
```

This will save the OpenAPI specification file in the `openapi_spec/` directory.
