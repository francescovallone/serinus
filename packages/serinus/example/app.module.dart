import 'package:serinus/serinus.dart';

import 'app.controller.dart';
import 'data/data.module.dart';

@Module(
  imports: [DataModule()],
  controllers: [AppController]
)
class AppModule extends SerinusModule{

  const AppModule();

}