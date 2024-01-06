
import 'package:serinus/serinus.dart';

import 'app.service.dart';

@Controller()
class AppController extends SerinusController{

  final AppService appService;

  const AppController(this.appService);

  @Get()
  Future<String> ping() async {
    return appService.ping();
  }

  @Get(path: ':id')
  Future<String> pong(@Param('id') String id) async {
    return appService.ping();
  }

}