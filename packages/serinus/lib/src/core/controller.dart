import 'package:meta/meta.dart';
import '../commons/commons.dart';
import '../commons/extensions/iterable_extansions.dart';
import '../commons/internal_request.dart';
import 'contexts/request_context.dart';
import 'route.dart';

abstract class Controller {

  final String path;

  Controller({
    required this.path,
  });

  final List<Route> _routes = [];

  @mustCallSuper
  void on<R extends Route>(R route){
    final routeExists = _routes.any((r) => r == R);
    if(routeExists){
      throw StateError('A route of type $R already exists in this controller');
    }
    _routes.add(route);
  }

  List<Route> get routes => _routes;

  @mustCallSuper
  @nonVirtual
  Future<void> handle(
    RequestContext context,
    Type routeCls,
    InternalRequest request
  ) async {
    var wrappedRequest = Request(request);
    final route = _routes.firstWhereOrNull((r) => r.runtimeType == routeCls);
    if(route == null){
      throw StateError('Route not found');
    }
    if(context.middlewares.isNotEmpty){
      final routeMiddlewares = context.middlewares.where((m) => m.routes.contains(route.path) || m.routes.contains('*'));
      for(final middleware in routeMiddlewares){
        (context, wrappedRequest) = await middleware.use(context, wrappedRequest);
      }
    }
    context.body = route.body?.call(await request.body(), request.contentType);
    print(context.body.runtimeType);
    print(request.contentType);
    await route.handle(context, Response(request.response()));
  }

  @mustCallSuper
  @nonVirtual
  bool hasRoute(String path, String method){
    return _routes.any((r) => r.path == path && r.method == method);
  }

}