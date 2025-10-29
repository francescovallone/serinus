import 'dart:io';

import 'package:echo/generated/helloworld.pbgrpc.dart';
import 'package:grpc/grpc.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_microservices/transporters/grpc/grpc_controller.dart';
import 'package:serinus_microservices/transporters/grpc/grpc_transport.dart';

class GreeterService extends GreeterServiceBase {
  @override
  Future<HelloReply> sayHello(
      ServiceCall call, HelloRequest request) async {
    final reply = HelloReply()..message = 'Hello, ${request.name}!';
    return reply;
  }
}

class AppController extends Controller with GrpcController {

  AppController() : super('/') {
    grpc(
      GrpcRoute(GreeterService, 'SayHello'),
      (call, request, context) async {
        final helloRequest = request as HelloRequest;
        final reply = HelloReply()..message = context.use<GreeterProvider>().getGreeting(helloRequest.name);
        return reply;
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
