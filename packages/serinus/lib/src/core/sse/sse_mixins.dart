import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:uuid/v4.dart';

import '../../contexts/sse_context.dart';
import '../../enums/http_method.dart';
import '../core.dart';

/// A mixin that adds support for Server-Sent Events (SSE) to a controller.
mixin SseController on Controller {
  final Map<String, RouteHandler> _sseRoutes = {};

  /// The [sseRoutes] property contains the SSE routes of the controller.
  Map<String, RouteHandler> get sseRoutes => UnmodifiableMapView(_sseRoutes);

  /// This method is called when a new SSE route is registered.
  @mustCallSuper
  void onSse<R extends Route>(
    R route,
    Stream Function(SseContext context) handler, {
    List<Pipe> pipes = const [],
  }) {
    if (route.method != HttpMethod.get) {
      throw StateError('SSE routes must use GET method. [${route.method}]');
    }
    final sseRouteExists = _sseRoutes.values.any(
      (r) => r.route.path == route.path,
    );
    final routeExists = routes.values.any(
      (r) => r.route.path == route.path && r.route.method == route.method,
    );
    if (sseRouteExists || routeExists) {
      throw StateError(
        'A route with the same path already exists. [${route.path}]',
      );
    }

    _sseRoutes[UuidV4().generate()] = (
      handler: handler,
      route: route,
      schema: null,
      body: null,
    );
  }
}
