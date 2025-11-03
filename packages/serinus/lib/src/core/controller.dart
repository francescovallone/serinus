import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:uuid/v4.dart';

import '../containers/hooks_container.dart';
import '../contexts/contexts.dart';
import 'core.dart';

/// Shortcut for a request-response handler. It takes a [RequestContext] and returns a [Response].
typedef ReqResHandler<T> = Future<T> Function(RequestContext context);

/// The [RouteHandlerSpec] class is used to define a route handler specification.
abstract class RouteHandlerSpec<T> {

  /// The [route] property contains the route information.
  final Route route;
  /// The [handler] property contains the handler function.
  final T handler;

  /// The [RouteHandlerSpec] constructor is used to create a new instance of the [RouteHandlerSpec] class.
  RouteHandlerSpec(
    this.route,
    this.handler
  );
  
}

/// The [RestRouteHandlerSpec] class is used to define a REST route handler specification.
class RestRouteHandlerSpec<T> extends RouteHandlerSpec<ReqResHandler<T>> {

  /// The [shouldValidateMultipart] property determines if multipart form data should be validated.
  final bool shouldValidateMultipart;

  /// The [isStatic] property determines if the route is static.
  final bool isStatic;

  /// The [RestRouteHandlerSpec] constructor is used to create a new instance of the [RestRouteHandlerSpec] class.
  RestRouteHandlerSpec(
    Route route,
    ReqResHandler<T> handler,
    {this.shouldValidateMultipart = false, this.isStatic = false}
  ) : super(route, handler);
}

/// The [Controller] class is used to define a controller.
abstract class Controller {
  /// The [version] property contains the version of the controller.
  int? get version => null;

  /// The [path] property contains the path of the controller.
  final String path;

  /// The [Controller] constructor is used to create a new instance of the [Controller] class.
  Controller(this.path);

  final Map<String, RestRouteHandlerSpec> _routes = {};

  /// The list of pipes to be applied.
  List<Pipe> pipes = [];

  /// The [routes] property contains the routes of the controller.
  Map<String, RestRouteHandlerSpec> get routes => UnmodifiableMapView(_routes);

  /// The [get] method is used to get a route.
  RestRouteHandlerSpec? get(String routeId) {
    return _routes[routeId];
  }

  /// The [hooksContainer] property contains the hooks container of the controller.
  final HooksContainer hooks = HooksContainer();

  /// The [exceptionFilters] property contains the exception filters of the controller.
  Set<ExceptionFilter> get exceptionFilters => {};

  /// The [metadata] property contains the metadata of the controller.
  List<Metadata> get metadata => [];

  /// The [on] method is used to register a route.
  ///
  /// It takes a [Route] and a [ReqResHandler].
  ///
  /// It should not be overridden.
  @mustCallSuper
  void on<R extends Route, T>(
    R route,
    ReqResHandler<T> handler, {
    bool shouldValidateMultipart = false,
  }) {
    final routeExists = _routes.values.any(
      (r) => r.route.path == route.path && r.route.method == route.method,
    );
    if (routeExists) {
      throw StateError(
        'A route with the same path and method already exists. [${route.path}] [${route.method}]',
      );
    }

    _routes[UuidV4().generate()] = RestRouteHandlerSpec(
      route,
      handler,
      shouldValidateMultipart: shouldValidateMultipart,
    );
  }

  /// The [onStatic] method is used to register a static route.
  /// It takes a [Route] and a [Object] value.
  ///
  /// It should not be overridden.
  @mustCallSuper
  void onStatic<R extends Route, T>(R route, T handler) {
    if (handler is Function) {
      throw StateError('The handler must be a static value');
    }
    final routeExists = _routes.values.any(
      (r) => r.route.path == route.path && r.route.method == route.method,
    );
    if (routeExists) {
      throw StateError(
        'A route with the same path and method already exists. [${route.path}] [${route.method}]',
      );
    }

    _routes[UuidV4().generate()] = RestRouteHandlerSpec(
      route,
      (_) async => handler,
      shouldValidateMultipart: false,
      isStatic: true,
    );
  }
}
