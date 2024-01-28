
import 'package:serinus/serinus.dart';

@Controller()
class AppController{

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