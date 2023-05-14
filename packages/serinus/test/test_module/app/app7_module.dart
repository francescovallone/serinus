// coverage:ignore-file
import 'package:serinus/serinus.dart';

import 'app_ws_controller.dart';
import 'app_ws_service.dart';
import 'websocket_provider.dart';

@Module(
  imports: [],
  controllers: [AppWsController],
  providers: [WebsocketProvider, AppWsService]
)
class AppWsModule extends SerinusModule{}