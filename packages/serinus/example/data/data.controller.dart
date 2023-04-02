
import 'package:serinus/serinus.dart';

import 'data.service.dart';

@Controller('/data')
class DataController extends SerinusController{

  final DataService dataService;

  const DataController(this.dataService);

  @Route("/", method: Method.post)
  Map<String, dynamic> ping(
    @Body() body,
  ){
    return {
      "hello": body.values
    };
  }

  @Route("/data", method: Method.get)
  Map<String, dynamic> data(){
    return {
      "hello": "HELLO"
    };
  }

}