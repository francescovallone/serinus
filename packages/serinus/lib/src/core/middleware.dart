import '../contexts/request_context.dart';
import '../http/http.dart';

/// The [NextFunction] type is used to define the next function of the middleware.
typedef NextFunction = Future<void> Function();

/// The [Middleware] class is used to define a middleware.
abstract class Middleware {
  /// The [routes] property contains the routes of the middleware.
  final List<String> routes;

  /// The [Middleware] constructor is used to create a new instance of the [Middleware] class.
  const Middleware({this.routes = const ['*']});

  /// The [use] method is used to execute the middleware.
  Future<void> use(RequestContext context, InternalResponse response,
      NextFunction next) async {
    return next();
  }
}
