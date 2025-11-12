![Serinus Banner](https://raw.githubusercontent.com/francescovallone/serinus/main/packages/serinus/assets/github-header.png)

<p align="center">
  <img src="https://img.shields.io/github/actions/workflow/status/francescovallone/serinus/serinus.yml?logo=dart&label=Tests" />
  <img src="https://img.shields.io/discord/1099781506978807919?logo=discord&logoColor=white" alt="Discord" />
  <img src="https://www.codefactor.io/repository/github/francescovallone/serinus/badge" alt="CodeFactor" />
</p>

# Serinus

Serinus provides a powerful and flexible framework for building server-side applications in Dart. Our open-source Dart framework, packages, and tools make it easy to create high-performance, scalable, and maintainable applications.

## Installation

To install Serinus you can either install the official CLI tool globally using pub:

```bash
dart pub global activate serinus_cli
```

or add Serinus to your `pubspec.yaml` file:

```bash
dart pub add serinus
```

## Create a new project

If you have installed the Serinus CLI tool, you can create a new Serinus project using the following command:

```bash
serinus create <project_name>
```

This will bootstrap a new Serinus project in a directory named `<project_name>`.

## Run the project

```bash
cd <project_name>
serinus run
```

By default the server will run on port 3000 and will listen for requests on localhost. You can change these settings modifying the file where you have defined the application (by default this file is `lib/main.dart`) or by passing the `--port` and `--host` flags to the `run` command:

```bash
serinus run --port=8080 --host=localhost
```

You can also start the application in development mode adding the `--dev` flag to the command:

```bash
serinus run --dev
```

In development mode the server will automatically restart when you change the source code.

## Documentation

You can find the documentation [here][documentation_link].

## License

Serinus is licensed under the MIT license. See the [LICENSE](LICENSE) file for more info.

# Contributing

If you want to contribute to Serinus, please read the [CONTRIBUTING](CONTRIBUTING.md) file.

## Our amazing sponsors

We would like to thank our sponsors for their support:

<p align="center">
  <a href="https://github.com/chimon2000" target="_blank" rel="noopener">
	<img src="https://avatars.githubusercontent.com/u/6907797?v=4" alt="Avatar: chimon2000" height="50"/>
  </a>
</p>

[repo_link]: https://github.com/francescovallone/serinus
[documentation_link]: https://serinus.app
