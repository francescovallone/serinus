# Exception Filters

Exception filters are a powerful mechanism in Serinus that allow you to handle exceptions thrown during the request-response cycle. They provide a way to catch and process exceptions, enabling you to return custom error responses or perform specific actions when an error occurs.

```dart
import 'package:serinus/serinus.dart';

class MyPipe extends Pipe {
  @override
  Future<void> transform(ExecutionContext context) async {
    // Transform the data here
  }
}
```