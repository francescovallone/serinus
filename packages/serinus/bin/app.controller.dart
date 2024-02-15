
import 'package:serinus/serinus.dart';

@Controller()
class AppController{

  const AppController();

  @Get()
  Future<String> ping(@Query('name2') String? name2, {
    @Query('name') String? name
  }) async {
    return '$name';
  }

  @Post()
  Future<String> pong(
    @Body() String name
  ) async {
    return 'pong';
  }

}