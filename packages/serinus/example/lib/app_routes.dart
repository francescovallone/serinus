import 'package:serinus/serinus.dart';

/// The [HelloWorldRoute] class is used to create a route that returns 'Hello, World!'.
class HelloWorldRoute extends Route {
  /// The constructor of the [HelloWorldRoute] class.
  HelloWorldRoute({super.queryParameters})
      : super(path: '/', method: HttpMethod.get);
}
