import 'package:serinus/serinus.dart';

/// The [AppProvider] class is used to provide the application.
class AppProvider extends Provider {
  /// The constructor of the [AppProvider] class.
  AppProvider();

  /// This method is used to send 'Hello, World!'.
  String sendHelloWorld() {
    return 'Hello world!';
  }
}
