import 'package:serinus/serinus.dart';

/// The class MiddlewareConsumer is used to configure the middleware
class MiddlewareConsumer{

  SerinusMiddleware? _middleware;

  SerinusMiddleware? get middleware => _middleware;

  List<ConsumerRoute> _excludedRoutes = [];
  List<ConsumerRoute> _forRoutes = [];

  List<ConsumerRoute> get excludedRoutes => _excludedRoutes;
  List<ConsumerRoute> get forRoutes => _forRoutes;

  /// The method [apply] is used to apply the middleware to the routes
  MiddlewareConsumer apply(SerinusMiddleware middleware, {List<ConsumerRoute> forRoutes = const []}){
    _middleware = middleware;
    _forRoutes = forRoutes;
    return this;
  }

  /// The method [excludeRoutes] is used to select the routes that will not be affected the middleware
  void excludeRoutes(List<ConsumerRoute> routes){
    if(routes.any((element) => forRoutes.indexWhere((route) => route.uri == element.uri && element.method == route.method) > -1)){
      throw new StateError("You can't exclude a route set in forRoutes!");
    }
    _excludedRoutes.clear();
    _excludedRoutes.addAll(routes);
  }

}