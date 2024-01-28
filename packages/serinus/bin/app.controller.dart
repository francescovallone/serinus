
import 'package:serinus/serinus.dart';

@Controller()
class AppController{

  const AppController();

  @Get()
  Future<String> ping() async {
    return 'pong';
  }

  @Post()
  Future<String> pong() async {
    return 'pong';
  }

}