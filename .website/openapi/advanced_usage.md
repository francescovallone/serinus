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
