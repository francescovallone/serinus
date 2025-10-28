import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';
import 'package:protobuf/protobuf.dart';

class GrpcRoute extends Route {
  
  GrpcRoute(Type serviceName, String methodName) : super(path: '/', method: HttpMethod.get);
}

typedef GrpcHandler<Req extends GeneratedMessage, Res extends GeneratedMessage> = 
  Future<Res> Function(ServiceCall call, Req request, RpcContext context);

mixin GrpcController on Controller implements RpcController {

  final Map<String, GrpcHandler> _grpcHandlers = {};

  void grpc<Req extends GeneratedMessage, Res extends GeneratedMessage>(
      String methodName, GrpcHandler<Req, Res> handler) {
    _grpcHandlers[methodName] = handler as GrpcHandler<GeneratedMessage, GeneratedMessage>;
  }

}