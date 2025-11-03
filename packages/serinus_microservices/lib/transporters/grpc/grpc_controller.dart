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
typedef GrpcHandler<Req extends GeneratedMessage, Res extends GeneratedMessage> = 
  Future<Res> Function(ServiceCall call, Req request, RpcContext context);

/// The [GrpcStreamHandler] typedef is the gRPC streaming handler function.
typedef GrpcStreamHandler<Req extends GeneratedMessage, Res extends GeneratedMessage> = 
  Stream<Res> Function(ServiceCall call, Stream<Req> requests, RpcContext context);

/// The [GrpcRouteSpec] class is used to define a gRPC route handler specification.
abstract class GrpcRouteSpec<T> extends RouteHandlerSpec<T> {
  
  /// The [GrpcRouteSpec] constructor is used to create a new instance of the [GrpcRouteSpec] class.
  GrpcRouteSpec(
    super.route,
    super.handler
  );

}

/// The [GrpcRouteHandlerSpec] class is the gRPC route handler specification.
class GrpcRouteHandlerSpec extends GrpcRouteSpec<GrpcHandler> {

  /// Creates a gRPC route handler specification.
  GrpcRouteHandlerSpec(
    GrpcRoute route,
    GrpcHandler handler,
  ) : super(route, handler);
}

/// The [GrpcStreamRouteHandlerSpec] class is the gRPC streaming route handler specification.
class GrpcStreamRouteHandlerSpec extends GrpcRouteSpec<GrpcStreamHandler> {

  /// Creates a gRPC stream route handler specification.
  GrpcStreamRouteHandlerSpec(
    GrpcRoute route,
    GrpcStreamHandler handler,
  ) : super(route, handler);
}

/// The [GrpcController] mixin is used to add gRPC routes to a controller.
mixin GrpcController on Controller {

  /// The [grpcRoutes] property contains the gRPC routes of the controller.
  final Map<String, GrpcRouteSpec> grpcRoutes = {};

  /// Registers a gRPC route with the controller.
  void grpc<Req extends GeneratedMessage, Res extends GeneratedMessage>(
      GrpcRoute route, GrpcHandler<Req, Res> handler) {
    if (grpcRoutes.containsKey(route.path)) {
      throw StateError(
        'A gRPC method with name "${route.path}" is already registered in the controller.',
      );
    }
    grpcRoutes[route.path] = GrpcRouteHandlerSpec(
      route,
      handler as GrpcHandler,
    );
  }

  /// Registers a gRPC streaming route with the controller.
  void grpcStream<Req extends GeneratedMessage, Res extends GeneratedMessage>(
      GrpcRoute route, GrpcStreamHandler<Req, Res> handler) {
    if (grpcRoutes.containsKey(route.path)) {
      throw StateError(
        'A gRPC streaming method with name "${route.path}" is already registered in the controller.',
      );
    }
    grpcRoutes[route.path] = GrpcStreamRouteHandlerSpec(
      route,
      handler as GrpcStreamHandler,
    );
  }

}
