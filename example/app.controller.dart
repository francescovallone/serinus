
import 'package:mug/mug.dart';

import 'data/data.service.dart';

@Controller(path: '')
class AppController extends MugController{

  final DataService dataService;

  const AppController(this.dataService);

  @Route("/", method: Method.get)
  Map<String, dynamic> ping(){
    return {
      "hello": "HELLO ${dataService.printHello("value")}"
    };
  }

  @Route("/", method: Method.post)
  Map<String, dynamic> data(){
    return {
      "hello": "HELLO"
    };
  }

}