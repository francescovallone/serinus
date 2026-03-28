import 'dart:async';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:grpc_example/generated/helloworld.pbgrpc.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_microservices/serinus_microservices.dart';

class GreeterService extends GreeterServiceBase {
  @override
  Stream<HelloReply> bidiHello(ServiceCall call, Stream<HelloRequest> request) {
    final greeting = call.context.use<GreeterProvider>();
    return request.asyncMap((helloRequest) {
      final message = greeting.getGreeting(helloRequest.name);
      return HelloReply()..message = message;
    });
  }

  @override
  Future<HelloReply> lotsOfGreetings(ServiceCall call, Stream<HelloRequest> request) {
    final greeting = call.context.use<GreeterProvider>();
    return request
        .asyncMap((helloRequest) => greeting.getGreeting(helloRequest.name))
        .toList()
        .then((greetings) => HelloReply()..message = greetings.join(', '));
  }
  
  @override
  Future<HelloReply> sayHello(ServiceCall call, HelloRequest request) {
    final greeting = call.context.use<GreeterProvider>();
    final message = greeting.getGreeting(request.name);
    return Future.value(HelloReply()..message = message);
  }
  
}

class AppController extends GrpcServiceController {

  AppController({
    required super.service,
  });

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
      AppController(service: GreeterService()),
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
        codecRegistry: CodecRegistry(codecs: const [
          GzipCodec(),
          IdentityCodec(),
        ]),
      ),
    ),
  );
  await microservice.serve();
}
