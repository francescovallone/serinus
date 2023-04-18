
import 'package:serinus/serinus.dart';

import 'data.service.dart';

@Controller('/data')
class DataController extends SerinusController{

  final DataService dataService;

  const DataController(this.dataService);

  @Post("/")
  Map<String, dynamic> ping(
    @Body() body,
  ){
    return {
      "hello": body.values
    };
  }

  @Get("/data")
  Map<String, dynamic> data(){
    return {
      "hello": "HELLO"
    };
  }

}