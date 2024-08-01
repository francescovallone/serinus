import 'package:dotenv/dotenv.dart';
import 'package:serinus/serinus.dart';

/// A service that provides access to environment variables.
class ConfigService extends Provider {
  @override
  bool get isGlobal => true;

  /// The [DotEnv] instance used to access environment variables.
  final DotEnv _dotEnv;

  ConfigService(this._dotEnv);

  /// Get the value of an environment variable or throw an exception if it is not set.
  ///
  /// Throws a [PreconditionFailedException] if the environment variable is not set.
  ///
  /// Example:
  ///
  /// ```dart
  /// final value = configService.getOrThrow('TEST');
  /// ```
  ///
  /// If the environment variable `TEST` is not set, this will throw a [PreconditionFailedException].
  String getOrThrow(String key) {
    return _dotEnv.getOrElse(
        key,
        () => throw PreconditionFailedException(
            message: 'Missing environment variable: $key'));
  }

  /// Get the value of an environment variable or return `null` if it is not set.
  ///
  /// Example:
  ///
  /// ```dart
  /// final value = configService.getOrNull('TEST');
  /// ```
  ///
  /// If the environment variable `TEST` is not set, this will return `null`.
  String? getOrNull(String key) {
    return _dotEnv[key];
  }
}
