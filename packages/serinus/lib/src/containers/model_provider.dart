/// A class that provides methods to convert a model to a [Map<String, dynamic>] and vice versa
abstract class ModelProvider {
  /// A list of models that can be converted to a [Map<String, dynamic>]
  List<Type> get toJsonModels;

  /// Converts a [Map<String, dynamic>] to a model of type [T]
  Object fromJson(Type model, Map<String, dynamic> json);

  /// Converts a model of type [T] to a [Map<String, dynamic>]
  Map<String, dynamic> toJson<T>(T model);
}
