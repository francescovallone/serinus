# Model Provider

The ModelProvider is a class used to provide a model to the handler. This is useful when you need to receive a JSON body and convert it to a Dart object.

Using the command `serinus generate models` you can generate a model provider class for your project.

```dart
import 'package:serinus/serinus.dart';

class MyObject {
  String name;

  MyObject({this.name});

  factory MyObject.from(Map<String, dynamic> json) {
    return MyObject(name: json['name']);
  }
}

class MyModelProvider extends ModelProvider {

  @override
  Object from(Type model, Map<String, dynamic> json);

  @override
  Map<String, dynamic> to<T>(T model);
}
```