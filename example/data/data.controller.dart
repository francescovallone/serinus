
import 'package:mug/mug.dart';

@Controller(path: '/data')
class DataController{

  const DataController();

  @Route("/", method: Method.get)
  Map<String, dynamic> ping(){
    return {
      "hello": "HELLO2"
    };
  }

  @Route("/data", method: Method.get)
  Map<String, dynamic> data(){
    return {
      "hello": "HELLO"
    };
  }

}