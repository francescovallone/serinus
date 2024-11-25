# Versioning

The technique of versioning allows to have different versions for controllers or routes within the same application.

Serinus supports 2 types of versioning:

| Type | Description |
| --- | --- |
| **URI** | The version will be passed in the URI of the request |
| **Header** | The version will be passed to the request through a custom header |

## URI Versioning

Using the URI versioning, the version will be passed in the URI of the request, such as `/v1/users`.

The following code snippet allows you to enable URI versioning:

```dart
import 'package:serinus/serinus.dart';

void main() {
    SerinusApplication application = await serinus.createApplication(
        entrypoint: AppModule()
    );
    application.versioning = VersioningOptions(
        type: VersioningType.uri,
        version: 1
    );
    await application.serve();
}
```

As can be seen, the `versioning` setter receives a `VersioningOptions` object, which contains the `type` and `version` parameters.

::: warning
The `version` parameter is required when using the URI versioning.
:::

## Header Versioning

Using the header versioning, the version will be passed to the request through a custom header, such as `X-API-Version: 1`.

The following code snippet allows you to enable header versioning:

```dart
import 'package:serinus/serinus.dart';

void main() {
    SerinusApplication application = await serinus.createApplication(
        entrypoint: AppModule()
    );
    application.versioning = VersioningOptions(
        type: VersioningType.header,
        version: 1,
        header: 'X-API-Version'
    );
    await application.serve();
}
```

As can be seen, the `versioning` setter also receives a `header` parameter, which is the name of the custom header that will be used in the application.

::: warning
The `header` parameter and the `version` parameter are required when using the header versioning.
:::

## Controller-Specific Versioning

If you want a controller to have a different version from the application, you can override the `version` getter in the controller.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {

    @override
    int get version => 2;

    MyController({super.path = '/'}) {
        on(GetRoute(path: '/'), (context) {
            return 'Hello, World!';
        });
    }
    
}
```

In this example, the `MyController` controller will have version 2, regardless of the version set in the application.

## Route-Specific Versioning

If you want a route to have a different version from the controller, you can override the `version` getter in the route.

```dart
import 'package:serinus/serinus.dart';

class MyRoute extends Route {

    @override
    int get version => 2;

    MyRoute({super.path = '/', super.method = HttpMethod.get});

}
```
