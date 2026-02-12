import 'package:serinus/serinus.dart';

import 'app_provider.dart';
import 'todo.dart';

class AppController extends Controller {

  AppController(): super('/'){
    on(Route.get('/'), _getAllTodos);
    on(Route.get('/<index>'), _getTodo);
    on<Todo, Map<String, dynamic>>(Route.post('/') , _createTodo);
    on(Route.put('/<index>'), _toggleTodo);
    on(Route.delete('/<index>'), _removeTodo);
  }

  Future<List<Todo>> _getAllTodos(RequestContext context) async {
    return context.use<AppProvider>().todos;
  }

  Future<Todo> _getTodo(RequestContext context) async {
    final index = int.tryParse(context.params['index'] ?? '');
    if (index == null) {
      throw BadRequestException('Invalid index');
    }
    final todos = context.use<AppProvider>().todos;
    if (todos.isEmpty || index < 0 || index >= todos.length) {
      throw NotFoundException('Todo not found');
    }
    return todos[index];
  }

  Future<Todo> _toggleTodo(RequestContext context) async {
    final index = int.tryParse(context.params['index'] ?? '');
    if (index == null) {
      throw BadRequestException('Invalid index');
    }
    context.use<AppProvider>().toggleTodoStatus(index);
    return context.use<AppProvider>().todos[index];
  }

  Future<Todo> _createTodo(RequestContext<Map<String, dynamic>> context) async {
    if (context.body['title'] == null) {
      throw BadRequestException('Invalid request body');
    }
    final title = context.body['title'] as String;
    context.use<AppProvider>().addTodo(title);
    return context.use<AppProvider>().todos.last;
  }

  Future<void> _removeTodo(RequestContext context) async {
    final index = int.tryParse(context.params['index'] ?? '');
    if (index == null) {
      throw BadRequestException('Invalid index');
    }
    context.use<AppProvider>().removeTodoAt(index);
  }


}