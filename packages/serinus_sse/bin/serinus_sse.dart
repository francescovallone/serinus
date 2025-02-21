import 'package:serinus/serinus.dart';
import 'package:serinus_sse/src/sse_context.dart';
import 'package:serinus_sse/src/sse_mixins.dart';
import 'package:serinus_sse/src/sse_module.dart';
import 'package:serinus_sse/src/sse_provider.dart';

class SseTest extends SseProvider with OnSseConnect {

  SseTest() : super('/sse');

  @override
  Stream<String> onConnect(String clientId) async* {
    print('Client connected: $clientId');
    yield 'Client connected: $clientId';
    await Future.delayed(Duration(seconds: 2));
    yield 'Client connected: $clientId';
  }

  @override
  Future<void> onMessage(
      String clientId, String data, SseContext context) async {
    print('Data received from client($clientId): $data');
    context.send('Data received: $data', clientId);
  }
}

class AppModule extends Module {
  AppModule() : super(providers: [SseTest()], imports: [SseModule()]);
}

void main(List<String> arguments) async {
  final application = await serinus.createApplication(entrypoint: AppModule());
  await application.serve();
}
