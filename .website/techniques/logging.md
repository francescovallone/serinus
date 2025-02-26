# Logger

Serinus comes with a built-in text-based logger which is used during application bootstrapping and several other circumstances such as displaying caught exceptions. This functionality is provided through the `Logger` class.

## Usage

The logger as a stand-alone class and will use the properties defined in the `LoggerService`.

```dart
class TestProvider extends Provider with OnApplicationInit {

  Logger logger = Logger('TestProviderFour');

  TestProvider();

  @override
  Future<void> onApplicationInit() async {
    logger.info('Provider initialized');
  }
}
```

This will print (if you have the default logger service):

```shell
[Serinus] 26252 20/09/2024 17:20:36     INFO [TestProviderFour] Provider initialized +0ms
```

## Change the logger prefix

You can change the prefix of the logger by using the `setLoggerPrefix` method from your application.

```dart
void main(List<String> arguments) async {
  SerinusApplication application = await serinus.createApplication(
      entrypoint: AppModule(), host: InternetAddress.anyIPv4.address);
  application.enableShutdownHooks();
  application.setLoggerPrefix('MyApp');
  await application.serve();
}
```

This will print:

```shell
[MyApp] 26252 20/09/2024 17:20:36     INFO [TestProviderFour] Provider initialized +0ms
```

## Configure the logger service

You can configure the logger service by using the `LoggerService` class.

```dart
void main(List<String> arguments) async {
  SerinusApplication application = await serinus.createApplication(
    entrypoint: AppModule(), 
    host: InternetAddress.anyIPv4.address,
    loggerService: LoggerService(
      level: LogLevel.debug,
      prefix: 'Serinus',
      onLog: (prefix, record, deltaTime) {
        print('{"prefix": "$prefix", "record": "${record.message}", "deltaTime": "${deltaTime}ms"}');
      },
    )
  );
  await application.serve();
}
```

Doing this you will change the default behavior of the logger service and it will print:

```shell
{"prefix": "Serinus", "record": "Provider initialized", "deltaTime": "0ms"}
```

## Log levels

The logger service has the following log levels:

| Level | Description |
|-------|-------------|
| debug | All logs will be printed |
| info  | All but debug logs will be printed |
| error | Only severe logs will be printed |
| none | No logs will be printed |
