
import 'package:serinus/serinus.dart';

import 'app.service.dart';

@Controller()
class AppController extends SerinusController{

  final AppService appService;

  const AppController(this.appService);

  @Get("/")
  String ping(){
    return appService.ping();
  }

}