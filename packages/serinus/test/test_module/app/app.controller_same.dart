// coverage:ignore-file
import 'package:serinus/serinus.dart';


@Controller()
class AppControllerSame extends SerinusController{


  const AppControllerSame();

  @Get()
  Map<String, dynamic> ping(){
    return {
      "hello": "hello world"
    };
  }

  @Post(path: "/test")
  Map<String, dynamic> test(){
    return {
      "hello": "HELLO"
    };
  }

  @Post()
  Map<String, dynamic> data(){
    return {
      "hello": "HELLO"
    };
  }

}