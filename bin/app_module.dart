import 'package:mug/mug.dart';

import 'todo_module.dart';


class AppModule implements Module{
  AppModule();
  
  @override
  dynamic controller = AppController();
  
  @override
  List? imports = [
    TodoModule()
  ];
}

@Controller(
  path: ""
)
class AppController{
  const AppController();

  @Route("/", method: "POST")
  Map<String, dynamic> helloWorld(){
    return {
      "body": "Hello World!",
      "statusCode": 200
    };
  }

  @Route("/", method: "GET")
  Map<String, dynamic> hello(){
    return {
      "body": "Hello!",
      "statusCode": 200
    };
  }
  
}