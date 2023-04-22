import 'package:serinus/serinus.dart';

import 'app.controller.dart';
import 'app.service.dart';
import 'data/data.module.dart';

@Module(
  imports: [DataModule()],
  controllers: [AppController],
  providers: [AppService]
)
class AppModule extends SerinusModule{}