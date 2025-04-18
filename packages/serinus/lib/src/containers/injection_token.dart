import '../core/module.dart';

/// A simple class to represent an injection token.
extension type InjectionToken(String name) {

  /// The token is take from the object type
  factory InjectionToken.fromType(Type type) {
    return InjectionToken(type.toString());
  }

  /// The token is taken from the module name
  /// or the module type if the name is empty.
  factory InjectionToken.fromModule(Module module) {
    return module.token.isNotEmpty 
      ? InjectionToken(module.token)
      : InjectionToken.fromType(module.runtimeType);
  }

}