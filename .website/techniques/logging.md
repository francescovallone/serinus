# Logger

Serinus comes with a built-in text-based logger which is used during application bootstrapping and several other circumstances such as displaying caught exceptions. This functionality is provided through the `Logger` class.

## Usage

The Logger is an  implementation of the `LoggerService` interface. It is a general-purpose class annd exposes the actual logger hiding its implementation.
By default the default logger is the `ConsoleLogger`.

```dart
class TestProvider extends Provider with OnApplicationInit {

  final logger = Logger('TestProviderFour');

  TestProvider();

  @override
  Future<void> onApplicationInit() async {
    logger.info('Provider initialized');
  }
}
```

This will print (if you have the default logger service):

```shell
[Serinus] 26252 20/09/2024 17:20:36     INFO [TestProviderFour] Provider initialized
```

## Override the default logger

You can configure the default logger by providing a custom `LoggerService` implementation to the `Logger` constructor.

```dart
void main() {
  final application = await serinus.createApplication(
    entrypoint: AppModule(), 
    host: InternetAddress.anyIPv4.address, 
    logger: ConsoleLogger(prefix: 'Serinus New Logger')
  );
}
```

This will change the default logger prefix to `Serinus New Logger`:

```shell
[Serinus New Logger] 26252 20/09/2024 17:20:36     INFO [TestProviderFour] Provider initialized
```

## Custom Logger

You can also create a custom logger by implementing the `LoggerService` interface.

```dart
class CustomLogger implements LoggerService {
  
  /// Implement all the methods of the LoggerService interface

}

void main() {
  final application = await serinus.createApplication(
    entrypoint: AppModule(), 
    host: InternetAddress.anyIPv4.address, 
    logger: CustomLogger()
  );
}
```

## Logger Levels

The logger has several levels of logging, which are:

- `none`: No logging.
- `verbose`: Log virtually everything.
- `debug`: Log debug and higher.
- `info`: Log info and higher.
- `warning`: Log warning and higher.
- `severe`: Log severe and higher.
- `shout`: Log shout and higher.

You can set the logger level by providing it to the `Logger` constructor.

```dart
void main() {
  final application = await serinus.createApplication(
    entrypoint: AppModule(), 
    host: InternetAddress.anyIPv4.address, 
    logger: ConsoleLogger(
      prefix: 'Serinus New Logger', 
      levels: {LoggerLevel.warning}
    )
  );
}
```

This will only log warnings and higher:

```shell
[Serinus New Logger] 26252 20/09/2024 17:20:36     WARNING [TestProviderFour] Provider initialized
```

### Overriding Log Levels

Serinus allows you to override the log levels of the default logger without having to create a new instance of the logger.

```dart
void main() {
  final application = await serinus.createApplication(
    entrypoint: AppModule(), 
    host: InternetAddress.anyIPv4.address, 
    logLevels: {LoggerLevel.warning}
  );
}
```

If you provide both a custom logger and log levels, the log levels provided to the `createApplication` method will be ignored.

Also remember that if you do not provide a custom logger nor log levels, the default logger will be used with the `info` level if in production mode, or the `debug` level if in development mode.

## Console Logger Options

The `ConsoleLogger` class has several options that can be configured:

- `prefix`: The prefix of the logger.
- `levels`: The levels of the logger.
- `json`: Whether to log in JSON format.
- `timestamp`: Whether to log the time difference between the current log and the previous log.

::: info
If you set the `json` option to `true`, the `timestamp` option will be ignored.
:::

```dart
void main() {
  final application = await serinus.createApplication(
    entrypoint: AppModule(), 
    host: InternetAddress.anyIPv4.address, 
    logger: ConsoleLogger(
      prefix: 'Serinus New Logger', 
      levels: {LoggerLevel.warning}, 
      json: true, 
    )
  );
}
```

This will log in JSON format:

```shell
{"prefix":"Serinus New Logger","pid":"22340","context":"Test","level":"WARNING","message":"Test","time":"2025-02-23T20:14:26.215734"}
```

## Logging Exceptions

You can log exceptions by passing the `OptionalParameters` class to the logger.

```dart
try {
  throw Exception('Test');
} catch (e) {
  logger.severe('An error occurred', OptionalParameters(error: e));
}
```
