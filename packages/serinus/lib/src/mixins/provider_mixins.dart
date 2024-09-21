import '../core/core.dart';

/// The mixin [OnApplicationInit] is used to define the method [onApplicationInit].
///
/// The method [onApplicationInit] is called in the providers when the application is initializing itself.
mixin OnApplicationInit on Provider {
  /// The [onApplicationInit] method is called in the providers when the application is initializing itself.
  Future<void> onApplicationInit();
}

/// The mixin [OnApplicationShutdown] is used to define the method [onApplicationShutdown].
///
/// The method [onApplicationShutdown] is called in the providers when the application is shutting down.
mixin OnApplicationShutdown on Provider {
  /// The [onApplicationShutdown] method is called in the providers when the application is shutting down.
  Future<void> onApplicationShutdown();
}

/// The mixin [OnApplicationReady] is used to define the method [onApplicationReady].
/// 
/// The method [onApplicationReady] is called in the providers after the [Application.serve] method has been executed.
mixin OnApplicationReady on Provider {
  /// The [onApplicationReady] method is called in the providers after the [Application.serve] method has been executed.
  Future<void> onApplicationReady();
}

/// The mixin [OnApplicationBootstrap] is used to define the method [onApplicationBootstrap].
/// 
/// The method [onApplicationBootstrap] is called in the providers after the [finalize] method of the ModulesContainer has been executed.
mixin OnApplicationBootstrap on Provider {
  /// The [onApplicationBootstrap] method is called in the providers after the [finalize] method of the ModulesContainer has been executed.
  Future<void> onApplicationBootstrap();
}
