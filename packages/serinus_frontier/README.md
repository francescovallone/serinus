![Serinus Banner](https://raw.githubusercontent.com/francescovallone/serinus/main/packages/serinus/assets/github-header.png)

# Serinus Frontier

Serinus Frontier is a plugin that allows you to use the Frontier library in your Serinus application.

## Installation

```bash
dart pub add serinus_frontier
```

## Usage

You can see the example usage in the example directory.

```dart
import 'package:serinus_frontier/serinus_frontier.dart';

class AppModule extends Module {

    AppModule() : super(
        imports: [FrontierModule([
            MyStrategy(
                MyStrategyOptions(), 
                (options, value, done) => done(value)
            )
        ])],
    );

}
