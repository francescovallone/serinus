import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';
import 'package:protobuf/protobuf.dart';

class GrpcRoute extends Route {

  final Type serviceName;

  final String methodName;

  GrpcRoute(this.serviceName, this.methodName) : super(path: '$serviceName.$methodName', method: HttpMethod.get);
}

typedef GrpcHandler<Req extends GeneratedMessage, Res extends GeneratedMessage> = 
  Future<Res> Function(ServiceCall call, Req request, RpcContext context);

mixin GrpcController on Controller {

  final Map<String, ({Route route, GrpcHandler handler})> grpcRoutes = {};

  void grpc<Req extends GeneratedMessage, Res extends GeneratedMessage>(
      GrpcRoute route, GrpcHandler<Req, Res> handler) {
    if (grpcRoutes.containsKey(route.path)) {
      throw StateError(
        'A gRPC method with name "${route.path}" is already registered in the controller.',
      );
    }
    grpcRoutes[route.path] = (
      route: route,
      handler: handler as GrpcHandler<GeneratedMessage, GeneratedMessage>
    );
  }

}