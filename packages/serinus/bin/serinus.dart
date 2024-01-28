import 'package:serinus/serinus.dart';
import 'package:serinus/src/serinus_application.dart';

import 'app.module.dart';

void main(List<String> arguments) async {
  SerinusApplication application = Serinus.createApp(
    entrypoint: AppModule
  );
  await application.serve();
  await application.close();
}
