# Getting Started

## Create a new project

To create a new project you can use the default command to build command-line applications in dart:

```bash
dart create <project_name>
```

## Installation

To install Serinus you can use the following command:

```bash
dart pub add serinus
```

## Next steps

Now you are ready to start building your application.
It is suggested to build the logic of the application inside the `lib` folder and to define the entry point of the application in the `bin/<project_name>` file. It will be easier to test the application using the `dart run` command.

## Our first application

Let's create a simple application that listens for requests on port 3000 and returns a simple message.

First, create a new file in the `lib` folder called `app_module.dart` and add the following code:

```dart

import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule() : super(
    imports: [], // Add the modules that you want to import
    controllers: [],
    providers: [],
    middlewares: []
  );
}

```

Then, in your `bin/<project_name>.dart` file add the following code:

```dart

import 'package:serinus/serinus.dart';
import 'package:<project_name>/app_module.dart';

void main(List<String> arguments) async {
  SerinusApplication application = await SerinusFactory.createApplication(
    entrypoint: AppModule()
  );
  await application.serve();
}

```

Finally, run the application using the following command:

```bash
dart run
```

Your applications is now running and listening for requests on port 3000.
