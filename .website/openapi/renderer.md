# Renderers

Serinus currently supports two different OpenAPI renderers:

- [Swagger](https://swagger.io/) (default)
- [Scalar](https://scalar.com/)

You can choose which renderer to use by specifying the options for that specific renderer in the `OpenApiModule` constructor.

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
        renderer: SwaggerUIOptions(), // Use Swagger renderer
        // renderer: ScalarUIOptions(), // Use Scalar renderer
      )
    ],
    controllers: [
      AppController(),
    ],
    providers: [],
  );
}
```

## Swagger Renderer

The swagger renderer supports several customization options through the `SwaggerUIOptions` class:

| Option | Description |
|--------|-------------|
| cdn    | URL of the Swagger UI CDN. If null, uses the default CDN. |
| theme  | Name of the Swagger UI theme to use. If null, uses the default theme. |
| version| Version of Swagger UI CDN to use. Default is '4.15.5'. |
| domId  | The DOM element ID where Swagger UI will be rendered. Default is '#swagger-ui'. |
| darkMode | Enables dark mode for Swagger UI. Default is false. |

## Scalar Renderer

The scalar renderer right now supports only one customization option through the `ScalarUIOptions` class:

| Option | Description |
|--------|-------------|
| customCss    | Custom CSS styles to apply to the Scalar UI. |