import 'package:serinus/serinus.dart';

import 'app.module.dart';

void main(List<String> arguments) {
  SerinusFactory application = SerinusFactory.createApp(
    AppModule()
  );
  application.serve();
}
