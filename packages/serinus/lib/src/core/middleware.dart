import '../commons/request.dart';
import 'contexts/request_context.dart';


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