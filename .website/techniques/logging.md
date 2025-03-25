# Logger

Serinus comes with a built-in text-based logger which is used during application bootstrapping and several other circumstances such as displaying caught exceptions. This functionality is provided through the `Logger` class. 

The logging system is fully customizable and can be configured to log in different formats, levels, and destinations, here are some of the features:

- Disable logging
- Log in different levels (display only errors, warnings, etc.)
- Log in various formats (text, json)
- Override the default logger
- Customize the default logger extending it

You can also decide to create your own implementation of the `LoggerService` interface to log in a different way.

## Basic Configuration

To disable logging, you can set the logger level to `none`.

```dart
void main() {
  final application = await serinus.createApplication(
    entrypoint: AppModule(), 
    host: InternetAddress.anyIPv4.address, 
    logger: ConsoleLogger(level: {LogLevel.none})
  );
}
```

Otherwise you can set specific levels to log.

```dart
void main() {
  final application = await serinus.createApplication(
    entrypoint: AppModule(), 
    host: InternetAddress.anyIPv4.address, 
    logger: ConsoleLogger(level: {LogLevel.warning, LogLevel.severe})
  );
}
```

The set of valid levels is:

- `LogLevel.none`
- `LogLevel.verbose`
- `LogLevel.debug`
- `LogLevel.info`
- `LogLevel.warning`
- `LogLevel.severe`
- `LogLevel.shout`
- `LogLevel.all` (default)

To configure a prefix for the logger, you can use the `prefix` property.

```dart
void main() {
  final application = await serinus.createApplication(
    entrypoint: AppModule(), 
    host: InternetAddress.anyIPv4.address, 
    logger: ConsoleLogger(prefix: 'Serinus New Logger')
  );
}
```

This will change the default logger prefix to `Serinus New Logger`

Here is a list of the available options for the `ConsoleLogger`:

| Option | Description | Default |
|--------|-------------|---------|
| prefix | The prefix of the logger | Serinus |
| levels | The levels of the logger | {LogLevel.all} |
| json | Whether to log in JSON format | false |
| timestamp | Whether to log the time difference between the current log and the previous log | true |

## Using the Logger

The logger can be accessed through the `Logger` class.

```dart
import 'package:serinus/serinus.dart';

class AwesomeProvider extends Provider with OnApplicationInit {
  final Logger _logger = Logger('AwesomeProvider');

  @override
  Future<void> onApplicationInit() async {
    _logger.info('Initializing the provider');
  }
}
```

## Extending the built-in Logger

You can also extend the built-in logger to add more functionalities or to customize the default behavior.

```dart
import 'package:serinus/serinus.dart';

class MyLogger extends ConsoleLogger {
  MyLogger(String name) : super(name);

  @override
  void info(Object? message, [OptionalParameters? optionalParameters]) {
    print('[$name] $level: $message');
  }
}
```
