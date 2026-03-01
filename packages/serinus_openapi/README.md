![Serinus Banner](https://raw.githubusercontent.com/francescovallone/serinus/main/packages/serinus/assets/github-header.png)

# Serinus OpenAPI

A plugin to add OpenAPI Specification in your Serinus applications 🐤.

## Installation

```bash
dart pub add serinus_openapi
```

## Usage

Add the `OpenApiModule` to the imports of your main application module:

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';

import 'app_controller.dart';
import 'app_provider.dart';

class AppModule extends Module {
  AppModule()
      : super(
          imports: [
            OpenApiModule.v3(
              InfoObject(
                title: 'Serinus OpenAPI Example',
                version: '1.0.0',
                description: 'An example of Serinus with OpenAPI integration',
              ),
            )
          ],
          controllers: [AppController()],
          providers: [AppProvider()],
        );
}
```

## Custom annotation example

You can build analyzer-driven custom annotations by extending `OpenApiAnnotation`.

The package also includes an example `OperationId` annotation:

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';

class UsersController extends Controller {
  UsersController() : super('/users') {
    on(Route.get('/'), listUsers);
  }

  @OperationId('users.list')
  Future<String> listUsers(RequestContext context) async {
    return 'ok';
  }
}
```
