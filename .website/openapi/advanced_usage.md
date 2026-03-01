# Advanced Usage

Although the basic usage of the Serinus OpenAPI module is straightforward, there are several advanced options you can utilize to customize the generated OpenAPI specification.

## Version specific routes

Sometimes you would like to document different versions of your API. To achieve this, you can do the following:

:::code-group

```dart [Controller]
import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';

class VersionedController extends Controller {

  VersionedController() : super('/items') {
    on(
      ApiRoute.v2(
        path: '/',
        method: HttpMethod.get,
      ), 
      _getItemsV2
    );
  }

  Future<Map<String, dynamic>> _getItemsV2(RequestContext context) async {
    // Implementation for version 2 of the endpoint
    return {'version': 'v2', 'items': []};
  }

}
```

```dart [Module]
import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [
      OpenApiModule.v3(
        InfoObject(
          title: 'Versioned API Example',
          version: '1.0.0',
          description: 'An example of versioned API with Serinus OpenAPI',
        ),
        analyze: true,
      )
    ],
    controllers: [
      VersionedController(),
    ],
    providers: [],
  );
}
```

:::

The resulting OpenAPI specification won't include the versioned route because the module is generating a v3 specification and the route is being exposed as a v2 route.

## Annotations

The package exports some custom built-in annotations that you can use on your handler methods to customize the generated OpenAPI specification. For example, you can use the `@Body(MyObject)` annotation to specify that the request body of a handler method should be documented as an instance of `MyObject` in the generated OpenAPI specification.

::: info
These annotations are used only to make more robust assumptions about the structure of your code, the plugin will still try to generate a valid OpenAPI specification even if you don't use them, but they can be useful to avoid edge cases and to make the generated specification more accurate.
:::

Currently, the following annotations are available:

- `@Body()`: specifies the type of the request body for a handler method.
- `@Query()`: specifies the type of a query parameter for a handler method.
- `@Headers()`: specifies header metadata for a handler method.
- `@Responses()`: specifies response metadata for a handler method.

## Custom Annotations

You can also create your own custom annotations by extending the `OpenApiAnnotation` class. This can be useful to create more specific annotations that are tailored to your application's needs. For example, you can create an `@OperationId()` annotation that allows you to specify the operation ID for a handler method in the generated OpenAPI specification.

```dart
import 'package:serinus_openapi/serinus_openapi.dart';

@Target({TargetKind.method})
class OperationId extends OpenApiAnnotation {
  final String operationId;

  const OperationId(this.operationId);

  @override
  void apply(OpenApiRegistry registry, Handler handler) {
    registry.addOperationId(handler, operationId);
  }
}
```