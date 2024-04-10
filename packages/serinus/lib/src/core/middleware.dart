import 'package:serinus/serinus.dart';

typedef NextFunction = Future<void> Function();

abstract class Middleware {

  final List<String> routes;

  const Middleware({
    this.routes = const ['*']
  });

  Future<void> use(
    RequestContext context, 
    Request request, 
    InternalResponse response, 
    NextFunction next
  ) async {
    return next();
  }
}