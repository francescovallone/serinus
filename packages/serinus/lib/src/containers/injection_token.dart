import 'dart:collection';

import '../core/module.dart';
import '../core/provider.dart';

/// A simple class to represent an injection token.
extension type InjectionToken(String name) {
  static final _moduleTokens = LinkedHashMap<Module, InjectionToken>.identity();
  static final Map<String, int> _moduleCounters = {};

  /// The [global] token is used to register global providers.
  static final InjectionToken global = InjectionToken('global');

  /// The token is take from the object type
  factory InjectionToken.fromType(Type type) {
    return InjectionToken(type.toString());
  }

  /// The token is taken from the module name
  /// or the module type if the name is empty.
  factory InjectionToken.fromModule(Module module) {
    if (module.token.isNotEmpty) {
      return InjectionToken(module.token);
    }
    final existing = _moduleTokens[module];
    if (existing != null) {
      return existing;
    }
    final baseName = module.runtimeType.toString();
    final counter = (_moduleCounters[baseName] ?? 0) + 1;
    _moduleCounters[baseName] = counter;
    final generated = InjectionToken('$baseName#$counter');
    _moduleTokens[module] = generated;
    return generated;
  }

  /// The token is taken from the provider type
  factory InjectionToken.fromProvider(Provider provider) {
    if (provider is CustomProvider) {
      return InjectionToken.fromType(provider.token);
    } else {
      return InjectionToken.fromType(provider.runtimeType);
    }
  }
}
