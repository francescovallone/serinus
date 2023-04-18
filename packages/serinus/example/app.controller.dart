
import 'package:serinus/serinus.dart';

import 'data/data.service.dart';

@Controller()
class AppController extends SerinusController{

  final DataService dataService;

  const AppController(this.dataService);

  @Get("/")
  Map<String, dynamic> ping(){
    return {
      "hello": "HELLO ${dataService.printHello("value")}"
    };
  }

  @Post("/")
  Map<String, dynamic> data(
    @Body() body
  ){
    return {
      "hello": "HELLO",
      "body": body,
    };
  }

}