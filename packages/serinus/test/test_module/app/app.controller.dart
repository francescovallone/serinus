// coverage:ignore-file
import 'package:serinus/serinus.dart';

import '../data/data.service.dart';

@Controller()
class AppController extends SerinusController{

  final DataService appService;

  const AppController(this.appService);

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