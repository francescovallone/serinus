import '../core/core.dart';

/// The mixin [OnApplicationInit] is used to define the method [onApplicationInit].
///
/// The method [onApplicationInit] is called in the providers when the application is initializing itself.
mixin OnApplicationInit on Provider {
  Future<void> onApplicationInit();
}

/// The mixin [OnApplicationShutdown] is used to define the method [onApplicationShutdown].
///
/// The method [onApplicationShutdown] is called in the providers when the application is shutting down.
mixin OnApplicationShutdown on Provider {
  Future<void> onApplicationShutdown();
}
