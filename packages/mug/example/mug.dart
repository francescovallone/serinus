import '../lib/mug.dart';

import 'app.module.dart';

void main(List<String> arguments) {
  MugFactory application = MugFactory.createApp(
    AppModule(), 
    address: '0.0.0.0'
  );
  application.serve();
}
