import 'package:serinus/serinus.dart';


abstract class Middleware {

  final List<String> routes;

  const Middleware({
    this.routes = const ['*']
  });

  Future<(
    RequestContext context,
    Request request,
  )> use(RequestContext context, Request request) async {
    return (context, request);
  }
}