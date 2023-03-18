
import 'package:mug/mug.dart';

import 'data.service.dart';

@Controller('/data')
class DataController extends MugController{

  final DataService dataService;

  const DataController(this.dataService);

  @Route("/", method: Method.post)
  Map<String, dynamic> ping(
    @Body() body,
  ){
    return {
      "hello": dataService.printHello("god")
    };
  }

  @Route("/data", method: Method.get)
  Map<String, dynamic> data(){
    return {
      "hello": "HELLO"
    };
  }

}