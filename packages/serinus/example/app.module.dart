import 'package:serinus/serinus.dart';

import 'app.controller.dart';
import 'app.service.dart';
import 'data/data.module.dart';
import 'websocket.dart';

@Module(
  imports: [DataModule()],
  controllers: [AppController],
  providers: [WebsocketGateway, AppService]
)
class AppModule extends SerinusModule{}