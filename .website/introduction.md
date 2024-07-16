# Serinus

Serinus is a minimalistic framework for building efficient and scalable server-side applications powered by Dart. 🎯

## Why Serinus?

Serinus is simple to use and easy to understand. It is also designed to be flexible and extensible, allowing you to build applications the way you want. In short - Serinus is a framework that gets out of your way and lets you focus on building your application.

## Installation

### Serinus CLI <Badge type="tip">Recommended ✨</Badge>

```console
dart pub global activate serinus_cli

serinus create my_project
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

This is the recommended way to start a new Serinus project.

### Pub

You can also add Serinus to your existing Dart project using `pub`:

```console
dart pub add serinus
```

This approach is not recommended for new projects as it requires manual setup.
