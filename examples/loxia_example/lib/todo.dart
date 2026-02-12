import 'package:serinus/serinus.dart';

class Todo with JsonObject{
  final String title;
  bool isDone;

  Todo({
    required this.title,
    this.isDone = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isDone': isDone,
    };
  }
}