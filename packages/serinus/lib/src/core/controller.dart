import 'package:meta/meta.dart';
import 'package:serinus/src/commons.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';
import 'package:serinus/src/commons/request.dart';

import 'route.dart';

abstract class Controller {

  final String path;

  Controller({
    required this.path,
  });

  final List<Route> _routes = [];

  @mustCallSuper
  void on<R extends Route>(R route, void Function(R route) callback){
    final routeExists = _routes.any((r) => r == R);
    if(routeExists){
      throw StateError('A route of type $R already exists in this controller');
    }
    _routes.add(route);
  }

  List<Route> get routes => _routes;

  @mustCallSuper
  Future<void> handle(InternalRequest request) async {
    final route = _routes.firstWhereOrNull((r) => r.path == request.path && r.method == request.method.toHttpMethod());
    if(route == null){
      throw StateError('No route found for path ${request.path} and method ${request.method}');
    }
    await route.handle(request, Response(request.response()));
  }

  @mustCallSuper
  bool hasRoute(String path, String method){
    return _routes.any((r) => r.path == path && r.method == method);
  }

}