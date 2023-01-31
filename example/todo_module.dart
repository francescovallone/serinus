import 'package:mug/mug.dart';

class TodoModule implements Module{

  TodoModule();
  
  @override
  List<dynamic> controllers = [
    TodoController()
  ];
  
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

  @Route("/",)
  List<Map<String, dynamic>> getAll(){
    return todos;
  }

  @Route("/number/:string", statusCode: 500)
  Map<String, dynamic> todo(
    @Query("id") String string,
    @Query("string", nullable: true) String? lel,
    @Param("string") String id
  ){
    return {
      "id": string,
      "lel": lel,
      "string": id
    };
  }

  @Route("/:id")
  Map<String, dynamic> get(@Param("id") String? id){
    return {
      "id": id
    };
  }

  @Route("/", method: 'POST')
  String randomTodo(
    @Body() String body,
  ){
    return body.toString();
  }
}
