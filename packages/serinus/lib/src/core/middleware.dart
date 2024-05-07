import '../contexts/request_context.dart';
import '../http/http.dart';

typedef NextFunction = Future<void> Function();

abstract class Middleware {
  final List<String> routes;

  const Middleware({this.routes = const ['*']});

  Future<void> use(RequestContext context, InternalResponse response,
      NextFunction next) async {
    return next();
  }
}
