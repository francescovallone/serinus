
import 'package:mug/mug.dart';

@Controller(path: '')
class AppController{

  const AppController();

  @Route("/", method: Method.get)
  Map<String, dynamic> ping(){
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