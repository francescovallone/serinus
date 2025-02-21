![Serinus Banner](https://raw.githubusercontent.com/francescovallone/serinus/main/packages/serinus/assets/github-header.png)

# Serinus Config

Serinus Config is a package that allows you to load configuration files in your Serinus application.

## Installation

```bash
dart pub add serinus_config
```

## Usage

You can see the example usage in the example directory.

```dart
import 'package:serinus_config/serinus_config.dart';

class AppModule extends Module {

    AppModule() : super(
        imports: [ConfigModule()],
    );

}
