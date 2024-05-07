# Config <Badge type="tip" text="^0.2.1"/>

Serinus Config is a plugin that allows to load .env files in your Serinus application.

::: warning
This plugin uses the [dotenv](https://pub.dev/packages/dotenv) package to load the .env files.
:::

## Installation

The installation of the plugin is immediate and can be done using the following command:

```bash
dart pub add serinus_config
```

## Usage

To use the plugin, you need to import it in your entrypoint module:

```dart
import 'package:serinus_config/serinus_config.dart';
import 'package:serinus/serinus.dart';

class AppModule extends Module {

  AppModule() : super(imports: [ConfigModule()]);

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
