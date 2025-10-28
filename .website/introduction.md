# Introduction

Serinus is a framework for building robust and scalable [Dart](https://dart.dev) server-side applications. It leverges the power of OOP and the flexibility of [Dart](https://dart.dev) to provide a simple and efficient way to build server-side applications.

Built on the bare HttpServer of Dart, Serinus provides a set of tools and utilities to make the development of server-side applications easier and more efficient. And even if the framework is not a wrapper around shelf, it provides a way to use shelf middlewares and handlers allowing the developer to leverage on already existing shelf packages.

## Motivation

At first, Serinus was created to learn more about the Dart language and to understand the internals of a web framework. But as the project grew, the goal of the project has changed.

The current state of the Dart ecosystem is not the best for building server-side applications. The frameworks are there but they are not as mature as other languages like NodeJS or Python. So, the goal of Serinus is to provide a modern and efficient framework for building server-side applications in Dart that can compete with other languages.

Together with the other packages of [Avesbox](https://avesbox.com), Serinus aims to provide a complete ecosystem for building web applications in Dart.

## Installation

To get started, you can either scaffold the project with the Serinus CLI, or create a new Dart project and add the Serinus package to the `pubspec.yaml` file.

To scaffold the project with the Serinus CLI, run the following command. This command will create a new Dart project with the Serinus package already added to the `pubspec.yaml` file and the necessary files to get started.

```bash
dart pub global activate serinus_cli
serinus create my_project
```

You can now navigate to the project folder and run the following command to start the server.

```bash
dart pub get
serinus run --dev
```

This will start the server on `http://localhost:3000` in development mode allowing you to leverage on an hot-restarter to automatically restart the server when a file is changed.


