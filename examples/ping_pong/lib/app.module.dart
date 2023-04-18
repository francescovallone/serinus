import 'package:serinus/serinus.dart';

import 'app.controller.dart';
import 'app.service.dart';

@Module(
  imports: [],
  controllers: [AppController],
  providers: [AppService],
)
class AppModule extends SerinusModule{}