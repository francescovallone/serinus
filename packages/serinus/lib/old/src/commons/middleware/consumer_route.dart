/// A class that represents a route that can be consumed by a [SerinusMiddleware].
class ConsumerRoute{
  /// The method of the route as a [String]
  String? method;
  Uri uri;

  /// The constructor of the [ConsumerRoute] class
  ConsumerRoute(this.uri, [this.method]);
}