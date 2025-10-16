# Config

A lot of times, applications need to manage configuration variables, such as database connection strings, API keys, and other sensitive information. The `serinus_config` plugin provides a simple way to manage these configuration variables using environment variables.

::: info
This plugin uses the [dotenv](https://pub.dev/packages/dotenv) package to load the .env files.
:::

## Installation

The installation of the plugin is immediate and can be done using the following command:

```bash
dart pub add serinus_config
```

## Getting Started

Once the plugin is installed, you need to import the `ConfigModule` in your root module. The `ConfigModule` is global, so you don't need to import it in other modules.

```dart
import 'package:serinus_config/serinus_config.dart';
import 'package:serinus/serinus.dart';

class AppModule extends Module {

  AppModule() : super(imports: [ConfigModule()]);

}
```

The above code will load the `.env` file located in the root of your project and make the variables available throughout the application using the `ConfigService`.

To use the `ConfigService`, you need to inject it into your controller or service using the `context.use<ConfigService>()` method.

```dart
import 'package:serinus/serinus.dart';

class MyController extends Controller {

  MyController() : super('/') {
    on(Route.get('/'), _handleHelloWorld);
  }

  String _handleHelloWorld(RequestContext context) {
    final config = context.use<ConfigService>();
    final apiUrl = config.get('API_URL');
    return 'API URL is: $apiUrl';
  }

}

```

### Options

The plugin allows you to specify the path of the .env file to load using the `dotEnvPath` parameter. The default value is `.env`.

```dart
import 'package:serinus_config/serinus_config.dart';
import 'package:serinus/serinus.dart';

class AppModule extends Module {

  AppModule() : super(imports: [ConfigModule(dotEnvPath: '.env')]);

}
```
