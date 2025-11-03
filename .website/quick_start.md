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
