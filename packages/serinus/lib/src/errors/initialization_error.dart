/// The [InitializationError] should be thrown when something during
/// the initialization of the Serinus Application went wrong not for an error
/// of the library but caused by the user.
class InitializationError extends Error {
  /// Message describing the initialization error.
  final String? message;

  /// The [InitializationError] constructor is used to create a new instance of the [InitializationError] class.
  InitializationError([this.message]);

  @override
  String toString() {
    if (message != null) {
      return 'Initialization failed: $message';
    }
    return 'Initialization failed';
  }
}
