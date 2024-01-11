
import 'package:serinus/serinus.dart';

import 'app.service.dart';

@Controller()
class AppController extends SerinusController{

  const AppController();

  @Get()
  Future<String> ping() async {
    return 'pong';
  }

  @Get(path: ':id')
  Future<String> pong(@Param('id') String id) async {
    return 'pong$id';
  }

}