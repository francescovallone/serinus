/// The kReleaseMode constants is used to determine if the application is running in a compiled release mode.
const bool kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// The kProfileMode constants is used to determine if the application is running in a profile mode.
const bool kProfileMode = bool.fromEnvironment('dart.vm.profile');

/// The kDebugMode constants is used to determine if the application is running in a debug mode.
/// In actuality it is true when kReleaseMode and kProfileMode are false.
const bool kDebugMode = !kReleaseMode && !kProfileMode;
