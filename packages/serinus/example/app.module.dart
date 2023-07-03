import 'package:serinus/serinus.dart';

import 'app.controller.dart';
import 'app.service.dart';
import 'app_service_copy.dart';
import 'data/data.module.dart';

@Module(
  imports: [DataModule()],
  controllers: [AppController],
  providers: [AppService, AppServiceCopy]
)
class AppModule extends SerinusModule{}