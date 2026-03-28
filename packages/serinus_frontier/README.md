# Serinus Frontier

![Serinus Banner](https://raw.githubusercontent.com/francescovallone/serinus/main/packages/serinus/assets/github-header.png)

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
    AppModule()
            : super(
                    imports: [
                        Provider.value<FrontierStrategy>()
                    ],
                );

}

class AppController extends Controller {
    AppController() : super('/') {
        on(
            Route.get('/', guards: {AuthGuard('MyStrategy')}),
            (context) async => 'authenticated',
        );
    }
}
```
