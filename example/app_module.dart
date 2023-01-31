import 'package:mug/mug.dart';

import 'todo_module.dart';


class AppModule implements Module{
  AppModule();
  
  @override
  List<dynamic> controllers = [
    AppController(),
  ];
  
  @override
  List? imports = [
    TestModule(),
    TodoModule()
  ];
}

@Controller(path: "/test")
class TestController{
  @Route("/")
  Map<String, dynamic> helloWorld(@RequestInfo() Request req){
    return {
      "body": "Hello World! ${req.path}",
      "statusCode": 200
    };
  }
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

class TestModule implements Module{
  TestModule();
  
  @override
  List<dynamic> controllers = [
    TestController()
  ];
  
  @override
  List? imports = [
    TodoModule()
  ];
}