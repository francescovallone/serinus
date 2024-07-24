import 'package:serinus/serinus.dart';
import 'package:serinus_sse/src/sse_adapter.dart';

class SseModule extends Module{

  @override
  Future<Module> registerAsync(ApplicationConfig config) async {

    final sseAdapter = SseAdapter(port: 8081);
    await sseAdapter.init();

    return this;
  }

  
}