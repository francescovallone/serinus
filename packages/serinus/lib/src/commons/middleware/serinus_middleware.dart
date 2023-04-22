import 'package:serinus/serinus.dart';

/// The class SerinusMiddleware is used to define a middleware
/// every middleware in the application must extend this class
abstract class SerinusMiddleware {
  /// The method [use] is used to execute the middleware
  /// 
  /// The [request] parameter is the request object
  /// 
  /// The [response] parameter is the response object
  /// 
  /// The [next] parameter is the function that will be executed after the middleware
  use(Request request, Response response, void Function() next);
}