import 'package:serinus/serinus.dart';
import 'package:serinus_sse/src/sse_module.dart';

class AppModule extends Module {

  AppModule(): super(imports: [SseModule()]);


}

void main(List<String> arguments) async {
  final application = await serinus.createApplication(entrypoint: AppModule());
  await application.serve();
}
