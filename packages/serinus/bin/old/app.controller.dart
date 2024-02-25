
import 'package:serinus/old/serinus.dart';

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
  Future<Map<String,dynamic>> pong(
    @Body() JsonBody name
  ) async {
    return name.toJson();
  }

}