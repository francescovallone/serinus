# Quick Start

Serinus is built on top of Dart so you need to have Dart installed on your machine. If you don't have Dart installed, you can download it from the [official website](https://dart.dev/get-dart).

## Create a new Serinus project

We recommend using the Serinus CLI to create a new project. You can install the CLI by running the following command:

```bash
dart pub global activate serinus_cli
```

Once you have the CLI installed, you can create a new project by running the following command:

```bash
serinus new my_project
```

This will create a new Serinus project in the `my_project` directory with the following structure:

```console
my_project
├── bin
│   ├── my_project.dart
├── lib
│   ├── app_controller.dart
│   ├── app_module.dart
│   ├── app_provider.dart
│   ├── app_routes.dart
│   ├── my_project.dart
├── config.yaml
├── pubspec.yaml
```

Once done you can navigate to the project directory:

```bash
cd my_project
```

And run the project:

```bash
serinus run
```

::: tip
If you add the `--dev` flag to the `serinus run` command, the server will automatically restart when you make changes to your code.
:::

This will start the Serinus server and you can access it by navigating to `http://localhost:3000` in your browser.