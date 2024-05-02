# Serinus

Serinus is a minimalistic framework for building efficient and scalable server-side applications and powered by Dart. 🎯

## Why Serinus?

Serinus aims to be a simple and easy-to-use framework for building server-side applications. It is inspired by [NestJS](https://nestjs.com/) and it is designed to be easy to use and to integrate with your existing projects. It also has a shallow learning curve to ensure that developers can start building applications quickly.

## Installation

::: warning
Serinus is still being developed and many things can change. Use it at your own risk.
:::

### Using the CLI
  
::: tip
The CLI is still under development and more features will be added in the future.
:::

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

### From pub.dev

```console
dart pub add serinus
```
