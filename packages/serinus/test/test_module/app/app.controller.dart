// coverage:ignore-file
import 'package:serinus/serinus.dart';

import '../data/data.service.dart';

@Controller()
class AppController extends SerinusController{

  final DataService dataService;

  const AppController(this.dataService);

  @Route("/", method: Method.get)
  Map<String, dynamic> ping(){
    return {
      "hello": "hello world"
    };
  }

  @Route("/test", method: Method.post)
  Map<String, dynamic> test(){
    return {
      "hello": "HELLO"
    };
  }

  @Route("/", method: Method.post)
  Map<String, dynamic> data(){
    return {
      "hello": "HELLO"
    };
  }

}