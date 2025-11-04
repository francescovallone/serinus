/// A class that provides methods to convert a model to a [Map<String, dynamic>] and vice versa
abstract class ModelProvider {
  /// A map of models that can be converted from a [Map<String, dynamic>]
  Map<String, Function> get fromJsonModels;

  /// A map of models that can be converted to a [Map<String, dynamic>]
  Map<String, Function> get toJsonModels;

  /// Converts a [Map<String, dynamic>] to a model of type [T]
  Object? from(String model, Map<String, dynamic> json) {
    return fromJsonModels['$model']?.call(json);
  }

  /// Converts a model of type [T] to a [Map<String, dynamic>]
  Map<String, dynamic> to<T>(T model) {
    return (toJsonModels['$T']?.call(model) ?? toJsonModels['${model.runtimeType}']?.call(model));
  }
}
