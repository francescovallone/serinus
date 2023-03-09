import 'package:mug/commons/middleware/mug_middleware.dart';
import 'package:mug/commons/middleware/consumer_route.dart';

class MiddlewareConsumer{

  late MugMiddleware _middleware;

  MugMiddleware get middleware => _middleware;

  List<ConsumerRoute> _excludedRoutes = [];

  List<ConsumerRoute> get excludedRoutes => _excludedRoutes;

  MiddlewareConsumer apply(MugMiddleware middleware){
    _middleware = middleware;
    return this;
  }

  void excludeRoutes(List<ConsumerRoute> routes){
    _excludedRoutes.clear();
    _excludedRoutes.addAll(routes);
  }

}