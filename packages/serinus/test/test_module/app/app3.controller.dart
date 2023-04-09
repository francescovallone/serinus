// coverage:ignore-file
import 'package:serinus/serinus.dart';

class AppControllerWrong extends SerinusController{

  const AppControllerWrong();

  @Get("/")
  Map<String, dynamic> ping(){
    return {
      "hello": "hello world"
    };
  }

  @Post("/test")
  Map<String, dynamic> test(){
    return {
      "hello": "HELLO"
    };
  }

  @Get("/")
  Map<String, dynamic> data(){
    return {
      "hello": "HELLO"
    };
  }

}