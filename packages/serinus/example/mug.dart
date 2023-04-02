import 'package:serinus/serinus.dart';

import 'app.module.dart';

void main(List<String> arguments) {
  SerinusFactory application = SerinusFactory.createApp(
    AppModule(), 
    address: '0.0.0.0'
  );
  application.serve();
}
