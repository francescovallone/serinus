// coverage:ignore-file
import 'package:mug/mug.dart';

class AppControllerWrong extends MugController{

  const AppControllerWrong();

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