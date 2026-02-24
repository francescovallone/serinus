# Quick Start

In this guide and in the following guides, you will learn the fundamentals of Serinus. To get familiar with the framework, we will create a simple CRUD application that will allow us to manage a list of users.

## Pre-requisites

Before we start, make sure you have Dart (version >= 3.9.0) installed on your machine. If you don't have Dart installed, you can follow the instructions [here](https://dart.dev/get-dart).

## Setup

To scaffold the project with the Serinus CLI, run the following command. This command will create a new Dart project with the Serinus package already added to the `pubspec.yaml` file and the necessary files to get started.

```bash
dart pub global activate serinus_cli
serinus create my_project
```

This command will create the my_project folder with the following structure:

```bash

my_project
├── bin
│   ├── my_project.dart
├── lib
│   ├── app_controller.dart
│   ├── app_module.dart
│   ├── app_provider.dart
│   ├── todo.dart
│   ├── my_project.dart
├── pubspec.yaml

```

Here is a brief explanation of the files and folders created:

| File/Folder | Description |
| --- | --- |
| `bin/my_project.dart` | The entry point of the application. |
| `lib/app_controller.dart` | The controller that will handle the requests. It contains the basics GET, POST, PUT, DELETE routes |
| `lib/app_module.dart` | The module that will contain the controllers and providers of the application. |
| `lib/app_provider.dart` | The provider that will handle the business logic of the application. |
| `lib/todo.dart` | The model that represents a Todo item. |
| `lib/my_project.dart` | The main file that will create the application and start the server. |

The `lib/my_project.dart` file contains the following code:

```dart[my_project.dart]
import 'package:serinus/serinus.dart';

Future<void> bootstrap() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
  );
  await app.serve();
}
```

To create a Serinus Application instance, we use the `serinus` global object to call the `createApplication` method. The `createApplication` method takes an `entrypoint` parameter that is an instance of a `Module` class. In this case, we are passing an instance of the `AppModule` class.

## Running the Application

You can now navigate to the project folder and run the following command to start the server.

```bash
dart pub get
serinus run --dev
```

This will start the server on `http://localhost:3000` in development mode allowing you to leverage on an hot-restarter to automatically restart the server when a file is changed.

## Let's complete it

So now we have the application running but we should start adding some features to see how things really work.

## Update the Todo model

The `Todo` class is already augmented with the `JsonObject` mixin, meaning that this object can be converted to its json representation by the framework. But we also need to create it directly from the body although not the `Todo` class itself so let's create a `TodoDto` class.

```dart
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

class TodoDto {

  final String title;

  const TodoDto({ 
    required this.title, 
  });

  factory TodoDto.fromJson(Map<String, dynamic> json) { 
    return TodoDto( 
      title: json['title'], 
    );
  } 
}

```

## Generate the models

As you can see the `TodoDto` class has a `fromJson` factory constructor that will be used by the cli to generate the [ModelProvider](/techniques/model_provider.html). So let's do exactly that.

Let's execute this command:

```bash
serinus generate models
```

And now we have a new file `model_provider` in the root of the `lib` folder.

```dart
import 'package:serinus/serinus.dart';

import 'todo.dart';

/// The [MyProjectModelProvider] is used to provide models for the Serinus application.
/// It contains mappings for serializing and deserializing models to and from JSON.
class MyProjectModelProvider extends ModelProvider {
  @override
  Map<String, Function> get toJsonModels {
    return {"Todo": (model) => (model as Todo).toJson()};
  }

  @override
  Map<String, Function> get fromJsonModels {
    return {"TodoDto": (json) => TodoDto.fromJson(json)};
  }
}
```

Let's add it to the application.

```dart
import 'package:serinus/serinus.dart';

import 'app_module.dart';
import 'model_provider.dart';

/// The bootstrap function is the entry point of the application.
/// It will be called by the `entrypoint` file in the bin directory.
/// 
/// This function creates a Serinus application using the [AppModule]
/// as the root module, and starts the server on host '0.0.0.0' and port 3000.
Future<void> bootstrap() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    host: '0.0.0.0',
    port: 3000,
    modelProvider: MyProjectModelProvider()
  );
  await app.serve();
}
```

## Use the model as the body in the TodoController

First of all let's create a Pipe to validate the body.

```dart
import 'package:serinus/serinus.dart';

import 'todo.dart';

class TodoPipe extends Pipe {
  @override
  Future<void> transform(ExecutionContext context) async {
    if (context.argumentsHost is! HttpArgumentsHost) {
      return;
    }
    final reqContext = context.switchToHttp();
    final body = reqContext.body;
    if (body is TodoDto) {
      if (body.title.isEmpty) {
        throw BadRequestException('Title cannot be empty');
      }
      return;
    }
    throw BadRequestException('The body is not correct!');
  }
}
```

Then let's bind the pipe to the controller and specify the DTO to the route that will create the `Todo`.

```dart
import 'package:serinus/serinus.dart';

import 'app_provider.dart';
import 'todo.dart';
import 'todo_pipe.dart';

class AppController extends Controller {

  AppController(): super('/'){
    /// ...
    on<Todo, TodoDto>(
      Route.post(
        '/',
        pipes: {
          TodoPipe()
        }
      ), 
      _createTodo
    );
    /// ...
  }

///...

  Future<Todo> _createTodo(RequestContext<TodoDto> context) async {
    context.use<AppProvider>().addTodo(context.body.title);
    return context.use<AppProvider>().todos.last;
  }

///...


}
```

Now when you do a `POST` request to `/` everything will be safe and sound.

## Conclusion

We've created a REST Api that automatically convert and validates the body of a request without code generation and **magic** stuff like that.
