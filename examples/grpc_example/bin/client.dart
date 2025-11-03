import 'package:grpc/grpc.dart';
import 'package:grpc_example/generated/helloworld.pbgrpc.dart';

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
    final response = await stub.lotsOfGreetings(
      Stream.fromIterable([
        HelloRequest()..name = 'World',
      ]),
    );
   print('Greeting: ${response.message}');
  } catch (e) {
    print('Caught error: $e');
  }
  await channel.shutdown();
}