import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:uuid/v4.dart';

import '../../contexts/sse_context.dart';
import '../../enums/http_method.dart';
import '../core.dart';

/// The [SseRouteHandlerSpec] class is used to define a Server-Sent Event (SSE) route handler specification.
class SseRouteHandlerSpec extends RouteHandlerSpec<Stream Function(SseContext)> {
  
  /// The [SseRouteHandlerSpec] constructor is used to create a new instance of the [SseRouteHandlerSpec] class.
  SseRouteHandlerSpec(
    super.route,
    super.handler
  );
}

/// A mixin that adds support for Server-Sent Events (SSE) to a controller.
mixin SseController on Controller {
  final Map<String, SseRouteHandlerSpec> _sseRoutes = {};

  /// The [sseRoutes] property contains the SSE routes of the controller.
  Map<String, SseRouteHandlerSpec> get sseRoutes => UnmodifiableMapView(_sseRoutes);

  /// This method is called when a new SSE route is registered.
  @mustCallSuper
  void onSse<R extends Route>(
    R route,
    Stream Function(SseContext context) handler) {
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

    _sseRoutes[UuidV4().generate()] = SseRouteHandlerSpec(
      route,
      handler,
    );
  }
}
