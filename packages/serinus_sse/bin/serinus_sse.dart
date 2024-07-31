import 'package:serinus/serinus.dart';
import 'package:serinus_sse/src/sse_context.dart';
import 'package:serinus_sse/src/sse_mixins.dart';
import 'package:serinus_sse/src/sse_module.dart';
import 'package:serinus_sse/src/sse_provider.dart';

class SseTest extends SseProvider with OnSseConnect{
  
  @override
  void onConnect(String clientId) {
    print('Client connected: $clientId');
  }

  @override
  Future<void> onResponse(String clientId, String data, SseContext context) async {
    print('Data received from client($clientId): $data');
    context.send('Data received: $data', clientId);
  }

}

class AppModule extends Module {

  AppModule(): super(
    providers: [SseTest()],
    imports: [SseModule()]
  );

}

void main(List<String> arguments) async {
  final application = await serinus.createApplication(entrypoint: AppModule());
  await application.serve();
}
