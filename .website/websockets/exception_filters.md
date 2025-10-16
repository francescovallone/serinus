# Exception Filters

There is no substantial difference between exception filters in WebSockets and HTTP. The same principles apply, and you can refer to the [Exception Filters](../exceptions/exception_filters.md) documentation for more details. The only difference is that instead of throwing a `SerinusException`, you should throw a `WsException`.

```dart
import 'package:serinus/serinus.dart';

class UnsupportedDataExceptionFilter extends ExceptionFilter {
  UnsupportedDataExceptionFilter() : super(catchTargets: [UnsupportedDataException]);

  @override
  Future<void> onException(ExecutionContext context, WsException exception) async {
    // Handle the exception and send an error message to the client
  }
}
```

## Gateway Exception Filters

You can bind an exception filter to a specific WebSocket gateway using the `exceptionFilters` property of the `WebSocketGateway` class.

```dart

import 'package:serinus/serinus.dart';

class MyGateway extends WebSocketGateway {
  @override
  Set<ExceptionFilter> get exceptionFilters => {UnsupportedDataExceptionFilter()};

  @override
  void onMessage(dynamic data, WebSocketContext context) {
    // Handle incoming messages
  }

}
```
