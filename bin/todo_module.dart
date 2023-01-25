import 'dart:math';
import 'package:mug/mug.dart';

class TodoModule implements Module{
  TodoModule();
  
  @override
  dynamic controller = TodoController();
  
  @override
  List? imports = [];
}


@Controller(
  path: "/todos"
)
class TodoController{
  final Logger logger = const Logger("TodoController");
  List<Map<String, dynamic>> todos = [];

  TodoController();

  @Route("/")
  List<String> getAll(){
    return [];
  }

  @Route("/:id")
  Map<String, dynamic> get(@Param("id") String? id){
    return {
      "id": id
    };
  }

  @Route("/", method: 'POST')
  Map<String, dynamic> randomTodo(){
    logger.info("HELLO");
    todos.add({
      "id": Random.secure().nextInt(100),
      "string": Random.secure().hashCode
    });
    return {
      "id": Random.secure().nextInt(100),
      "string": Random.secure().hashCode
    };
  }
}
