import 'dart:async';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:grpc_example/generated/helloworld.pbgrpc.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_microservices/transporters/grpc/grpc_controller.dart';
import 'package:serinus_microservices/transporters/grpc/grpc_transport.dart';

class GreeterService extends GreeterServiceBase {
  @override
  Stream<HelloReply> bidiHello(ServiceCall call, Stream<HelloRequest> request) {
    // TODO: implement bidiHello
    throw UnimplementedError();
  }

  @override
  Future<HelloReply> lotsOfGreetings(ServiceCall call, Stream<HelloRequest> request) {
    // TODO: implement lotsOfGreetings
    throw UnimplementedError();
  }
  
  @override
  Future<HelloReply> sayHello(ServiceCall call, HelloRequest request) {
    // TODO: implement sayHello
    throw UnimplementedError();
  }
  
}

class AppController extends Controller with GrpcController {

  AppController() : super('/') {
    grpcStream<HelloRequest, HelloReply>(
      GrpcRoute(GreeterService, 'LotsOfGreetings'),
      (call, request, context) async* {
        yield* request.map((req) {
          final provider = context.use<GreeterProvider>();
          final reply = provider.getGreeting(req.name);
          return HelloReply()..message = reply;
        });
      }
    );
    grpc<HelloRequest, HelloReply>(
      GrpcRoute(GreeterService, 'SayHello'),
      (call, request, context) async {
        final provider = context.use<GreeterProvider>();
        final reply = provider.getGreeting(request.name);
        return HelloReply()..message = reply;
      }
    );
    grpcStream<HelloRequest, HelloReply>(
      GrpcRoute(GreeterService, 'BidiHello'),
      (call, request, context) async* {
        await for (final req in request) {
          final provider = context.use<GreeterProvider>();
          final reply = provider.getGreeting(req.name);
          yield HelloReply()..message = reply;
        }
      }
    );
  }

}

class GreeterProvider extends Provider {
  String getGreeting(String name) {
    return 'Hello, $name!';
  }
}

class AppModule extends Module {
  AppModule(): super(
    providers: [
      GreeterProvider(),
    ],
    controllers: [
      AppController(),
    ],
  );
}

Future<void> main(List<String> arguments) async {
  final microservice = await serinus.createMicroservice(
    entrypoint: AppModule(),
    transport: GrpcTransport(
      GrpcOptions(
        port: 50051,
        host: InternetAddress.loopbackIPv4,
        services: [
          GreeterService(),
        ],
        codecRegistry: CodecRegistry(codecs: const [
          GzipCodec(),
          IdentityCodec(),
        ],
      )
    ))
  );
  await microservice.serve();
}
