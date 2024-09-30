import 'package:serinus/serinus.dart';

import 'test.dart';

class EchoModelProvider extends ModelProvider {
  @override
  Map<Type, Function> get toJsonModels {
    return {TestObject: (model) => (model as TestObject).toBody()};
  }

  @override
  Map<Type, Function> get fromJsonModels {
    return {TestObject: (json) => TestObject.fromRequest(json)};
  }

  @override
  Object from(
    Type model,
    Map<String, dynamic> json,
  ) {
    if (fromJsonModels.containsKey(model)) {
      return fromJsonModels[model]!(json);
    }
    throw UnsupportedError('Model $model not supported');
  }

  @override
  Map<String, dynamic> to<T>(T model) {
    if (toJsonModels.containsKey(T)) {
      return toJsonModels[T]!(model) as Map<String, dynamic>;
    }
    throw UnsupportedError('Model $T not supported');
  }
}
