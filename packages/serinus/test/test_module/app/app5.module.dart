// coverage:ignore-file
import 'package:serinus/old/serinus.dart';

import '../data/data.module.dart';
import 'app.controller.dart';
import 'app.controller_same.dart';

@Module(
  imports: [DataModule()],
  controllers: [AppController, AppControllerSame]
)
class AppControllerSameRoute extends SerinusModule{

}