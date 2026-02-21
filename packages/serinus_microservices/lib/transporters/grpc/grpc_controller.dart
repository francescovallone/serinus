import 'dart:async';

import 'package:grpc/grpc.dart';
import 'package:protobuf/protobuf.dart';
import 'package:serinus/serinus.dart';

/// The [GrpcRoute] class is the gRPC
class GrpcRoute extends Route {
  /// The [serviceName] property contains the name of the gRPC service.
  final Type serviceName;

  /// The [methodName] property contains the name of the gRPC method.
  final String methodName;

  /// Creates a gRPC route.
  GrpcRoute(this.serviceName, this.methodName) : super(path: '$serviceName.$methodName', method: HttpMethod.get);
}

/// The [GrpcHandler] typedef is the gRPC handler function.
class GrpcUnaryHandler<Req extends GeneratedMessage> {
  /// The handler function. It may transform the request; returning null means passthrough.
  final FutureOr<Req?> Function(ServiceCall call, Req request, RpcContext context) _handler;

  /// Creates a gRPC unary handler.
  GrpcUnaryHandler(this._handler);

  /// Calls the handler function.
  FutureOr<Req?> call(ServiceCall call, Req request, RpcContext context) {
    return _handler(call, request, context);
  }
}

/// Default forwarders that delegate to the underlying gRPC service through the invoker.
class GrpcDefaultForwarders {
  const GrpcDefaultForwarders._();

  /// Unary forwarder: runs the Serinus pipeline, then delegates to the service invoker.
  static Future<Req?> unary<Req extends GeneratedMessage, Res extends GeneratedMessage>(
    ServiceCall call,
    Req request,
    RpcContext context,
  ) async {
    // Return null to indicate passthrough of the original request.
    return null;
  }

  /// Streaming forwarder: runs the Serinus pipeline, then delegates to the service invoker.
  static Future<Stream<Req>?> stream<Req extends GeneratedMessage>(
    ServiceCall call,
    Stream<Req> requests,
    RpcContext context,
  ) async {
    // Return null to indicate passthrough of the original request stream.
    return null;
  }

}

/// The [GrpcStreamHandler] typedef is the gRPC stream handler function.
class GrpcStreamHandler<Req extends GeneratedMessage> {
  /// The handler function.
  final FutureOr<Stream<Req>?> Function(ServiceCall call, Stream<Req> requests, RpcContext context) _handler;

  /// Creates a gRPC stream handler.
  GrpcStreamHandler(this._handler);

  /// Calls the handler function.
  FutureOr<Stream<Req>?> call(ServiceCall call, Stream<Req> requests, RpcContext context) {
    return _handler(call, requests, context);
  }
}

/// The [GrpcRouteSpec] class is used to define a gRPC route handler specification.
abstract class GrpcRouteSpec<T, Req> extends RouteHandlerSpec<T> {
  @override
  T get handler => super.handler;

  /// The [GrpcRouteSpec] constructor is used to create a new instance of the [GrpcRouteSpec] class.
  GrpcRouteSpec(super.route, super.handler);
}

/// The [GrpcRouteHandlerSpec] class is the gRPC route handler specification.
class GrpcRouteHandlerSpec<Req extends GeneratedMessage>
    extends GrpcRouteSpec<GrpcUnaryHandler, Req> {
  /// Creates a gRPC route handler specification.
  GrpcRouteHandlerSpec(
    GrpcRoute route,
    FutureOr<Req?> Function(ServiceCall call, Req request, RpcContext context) handler,
  ) : super(route, GrpcUnaryHandler<Req>(handler));
}

/// The [GrpcStreamRouteHandlerSpec] class is the gRPC streaming route handler specification.
class GrpcStreamRouteHandlerSpec<Req extends GeneratedMessage>
    extends GrpcRouteSpec<GrpcStreamHandler, Req> {
  /// Creates a gRPC stream route handler specification.
  GrpcStreamRouteHandlerSpec(
    GrpcRoute route,
    FutureOr<Stream<Req>?> Function(ServiceCall call, Stream<Req> requests, RpcContext context) handler,
  ) : super(route, GrpcStreamHandler<Req>(handler));
}

/// The [GrpcController] mixin is used to add gRPC routes to a controller.
mixin GrpcController on Controller {
  /// The [grpcRoutes] property contains the gRPC routes of the controller.
  final Map<String, GrpcRouteSpec> grpcRoutes = {};

  /// Registers a gRPC route with the controller.
  void grpc<Req extends GeneratedMessage>(
    GrpcRoute route, [
    FutureOr<Req?> Function(ServiceCall call, Req request, RpcContext context)? handler,
  ]) {
    if (grpcRoutes.containsKey(route.path)) {
      throw StateError(
        'A gRPC method with name "${route.path}" is already registered in the controller.',
      );
    }
    grpcRoutes[route.path] = GrpcRouteHandlerSpec<Req>(
      route,
      handler ?? GrpcDefaultForwarders.unary,
    );
  }

  /// Registers a gRPC streaming route with the controller.
  void grpcStream<Req extends GeneratedMessage>(
    GrpcRoute route, [
    Stream<Req>? Function(ServiceCall call, Stream<Req> requests, RpcContext context)? handler,
  ]) {
    if (grpcRoutes.containsKey(route.path)) {
      throw StateError(
        'A gRPC streaming method with name "${route.path}" is already registered in the controller.',
      );
    }
    grpcRoutes[route.path] = GrpcStreamRouteHandlerSpec<Req>(
      route,
      handler ?? GrpcDefaultForwarders.stream,
    );
  }
}
