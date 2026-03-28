# Serinus Frontier

![Serinus Banner](https://raw.githubusercontent.com/francescovallone/serinus/main/packages/serinus/assets/github-header.png)

Serinus Frontier is a plugin that allows you to use the Frontier library in your Serinus application.

## Installation

```bash
dart pub add frontier serinus_frontier
```

## Usage

You can see the example usage in the example directory.

```dart
import 'package:serinus_frontier/serinus_frontier.dart';

class AppModule extends Module {
    AppModule()
            : super(
                    providers: [
                        HeaderFrontierStrategy(
                            HeaderStrategy(
                                HeaderOptions(key: 'Authorization', value: 'Bearer token'),
                                (options, result, done) async {
                                    done(result);
                                },
                            )
                        )
                    ]
                );

}

class AppController extends Controller {
    AppController() : super('/') {
        on(
            Route.get('/', guards: {AuthGuard<HeaderFrontierStrategy>()}),
            (context) async => 'authenticated',
        );
    }
}
```
