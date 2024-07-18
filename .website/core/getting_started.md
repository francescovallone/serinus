# Getting Started

## Create a new project

### Serinus CLI

The easiest way to create a new project is to use the CLI tool that we provide. To install the CLI tool you can use the following command:

```bash
dart pub global activate serinus_cli
```

Then you can create a new project using the following command:

```bash
serinus create <project_name>
```

### Dart CLI

To create a new project you can use the default command to build command-line applications in dart:

```bash
dart create <project_name>
```

Then to install Serinus you can use the following command:

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
    middlewares: [],
    exports: []
  );
}

```

Then, in your `bin/<project_name>.dart` file add the following code:

```dart

import 'package:serinus/serinus.dart';
import 'package:<project_name>/app_module.dart';

void main(List<String> arguments) async {
  SerinusApplication application = await serinus.createApplication(
    entrypoint: AppModule()
  );
  await application.serve();
}

```

The `AppModule` class is the entry point of the application.

Finally, run the application using the following command:

```bash
dart run
```

or using the following command if you are using the CLI tool:

```bash
serinus run
```

Your applications is now running and listening for requests on port 3000.

### Using the CLI tool

If you are using the CLI tool, then there are some interesting options to run the application:

- `--port`: The port to expose the application on. Default is `3000`.
- `--host`: The host to expose the application on. Default is `localhost`.
- `--dev`: Flag to run the application in development mode. If this flag is set, the application will be restarted every time a file is changed.
