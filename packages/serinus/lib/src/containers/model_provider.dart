/// A class that provides methods to convert a model to a [Map<String, dynamic>] and vice versa
abstract class ModelProvider {
  /// A map of models that can be converted from a [Map<String, dynamic>]
  Map<Type, Function> get fromJsonModels;

  /// A map of models that can be converted to a [Map<String, dynamic>]
  Map<Type, Function> get toJsonModels;

  /// A map of models that can be converted from the data of a [FormData] object

  /// Converts a [Map<String, dynamic>] to a model of type [T]
  Object from(Type model, Map<String, dynamic> json);

  /// Converts a model of type [T] to a [Map<String, dynamic>]
  Map<String, dynamic> to<T>(T model);
}
