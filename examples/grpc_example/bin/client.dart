import 'package:echo/generated/helloworld.pbgrpc.dart';
import 'package:grpc/grpc.dart';

Future<void> main() async {
  final channel = ClientChannel(
    'localhost',
    port: 50051,
    options: ChannelOptions(
      credentials: ChannelCredentials.insecure(),
      codecRegistry: CodecRegistry(codecs: const [
        GzipCodec(),
        IdentityCodec(),
      ]),
    ),
  );

  final stub = GreeterClient(channel);
  try {
    final response = await stub.sayHello(HelloRequest()..name = 'World');
    print('Greeter client received: ${response.message}');
  } catch (e) {
    print('Caught error: $e');
  }
  await channel.shutdown();
}