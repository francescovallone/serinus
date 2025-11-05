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
class GrpcUnaryHandler<Req extends GeneratedMessage, Res extends GeneratedMessage> {
  /// The handler function.
  final Future<Res> Function(ServiceCall call, Req request, RpcContext context) _handler;

  /// Creates a gRPC unary handler.
  GrpcUnaryHandler(this._handler);

  /// Calls the handler function.
  Future<Res> call(ServiceCall call, Req request, RpcContext context) {
    return _handler(call, request, context);
  }
}

/// The [GrpcStreamHandler] typedef is the gRPC stream handler function.
class GrpcStreamHandler<Req extends GeneratedMessage, Res extends GeneratedMessage> {
  /// The handler function.
  final Stream<Res> Function(ServiceCall call, Stream<Req> requests, RpcContext context) _handler;

  /// Creates a gRPC stream handler.
  GrpcStreamHandler(this._handler);

  /// Calls the handler function.
  Stream<Res> call(ServiceCall call, Stream<Req> requests, RpcContext context) {
    return _handler(call, requests, context);
  }
}

/// The [GrpcRouteSpec] class is used to define a gRPC route handler specification.
abstract class GrpcRouteSpec<T, Req, Res> extends RouteHandlerSpec<T> {
  @override
  T get handler => super.handler;

  /// The [GrpcRouteSpec] constructor is used to create a new instance of the [GrpcRouteSpec] class.
  GrpcRouteSpec(super.route, super.handler);
}

/// The [GrpcRouteHandlerSpec] class is the gRPC route handler specification.
class GrpcRouteHandlerSpec<Req extends GeneratedMessage, Res extends GeneratedMessage>
    extends GrpcRouteSpec<GrpcUnaryHandler, Req, Res> {
  /// Creates a gRPC route handler specification.
  GrpcRouteHandlerSpec(
    GrpcRoute route,
    Future<Res> Function(ServiceCall call, Req request, RpcContext context) handler,
  ) : super(route, GrpcUnaryHandler<Req, Res>(handler));
}

/// The [GrpcStreamRouteHandlerSpec] class is the gRPC streaming route handler specification.
class GrpcStreamRouteHandlerSpec<Req extends GeneratedMessage, Res extends GeneratedMessage>
    extends GrpcRouteSpec<GrpcStreamHandler, Req, Res> {
  /// Creates a gRPC stream route handler specification.
  GrpcStreamRouteHandlerSpec(
    GrpcRoute route,
    Stream<Res> Function(ServiceCall call, Stream<Req> requests, RpcContext context) handler,
  ) : super(route, GrpcStreamHandler<Req, Res>(handler));
}

/// The [GrpcController] mixin is used to add gRPC routes to a controller.
mixin GrpcController on Controller {
  /// The [grpcRoutes] property contains the gRPC routes of the controller.
  final Map<String, GrpcRouteSpec> grpcRoutes = {};

  /// Registers a gRPC route with the controller.
  void grpc<Req extends GeneratedMessage, Res extends GeneratedMessage>(
    GrpcRoute route,
    Future<Res> Function(ServiceCall call, Req request, RpcContext context) handler,
  ) {
    if (grpcRoutes.containsKey(route.path)) {
      throw StateError(
        'A gRPC method with name "${route.path}" is already registered in the controller.',
      );
    }
    grpcRoutes[route.path] = GrpcRouteHandlerSpec<Req, Res>(
      route,
      handler,
    );
  }

  /// Registers a gRPC streaming route with the controller.
  void grpcStream<Req extends GeneratedMessage, Res extends GeneratedMessage>(
    GrpcRoute route,
    Stream<Res> Function(ServiceCall call, Stream<Req> requests, RpcContext context) handler,
  ) {
    if (grpcRoutes.containsKey(route.path)) {
      throw StateError(
        'A gRPC streaming method with name "${route.path}" is already registered in the controller.',
      );
    }
    grpcRoutes[route.path] = GrpcStreamRouteHandlerSpec<Req, Res>(
      route,
      handler,
    );
  }
}
