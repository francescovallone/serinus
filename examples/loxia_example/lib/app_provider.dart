import 'package:serinus/serinus.dart';

import 'todo.dart';

class AppProvider extends Provider {

  List<Todo> todos = [];

  AppProvider();

  void addTodo(String name) {
    todos.add(Todo(
      title: name,
    ));
  }

  void toggleTodoStatus(int index) {
    todos[index].isDone = !todos[index].isDone;
  }

  void removeTodoAt(int index) {
    todos.removeAt(index);
  }

}