[![Serinus Logo][logo_white]][repo_link]

[![codecov](https://codecov.io/gh/francescovallone/serinus/branch/main/graph/badge.svg?token=A2337C1XGG)](https://codecov.io/gh/francescovallone/serinus)
![Pub Likes](https://img.shields.io/pub/likes/serinus?style=flat&logo=dart&label=Package%20likes&color=%23FF9800)
[![Pub Points](https://img.shields.io/pub/points/serinus?label=Package%20points&logo=dart)](https://pub.dev/packages/serinus/score)
[![Pub Version](https://img.shields.io/pub/v/serinus?color=green&label=Latest%20Version&logo=dart)](https://pub.dev/packages/serinus)
[![popularity](https://img.shields.io/pub/popularity/serinus?logo=dart&label=Package%20Popularity)](https://pub.dev/packages/serinus/score)

Serinus is a framework written in Dart for building efficient and scalable server-side applications.

# Getting Started

## Installation

To install Serinus you can use the following command:

```bash
dart pub global activate serinus_cli
```

## Create a new project

```bash
serinus create <project_name>
```

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

# License

Serinus is licensed under the MIT license. See the [LICENSE](LICENSE) file for more info.

# Contributing

If you want to contribute to Serinus, please read the [CONTRIBUTING](CONTRIBUTING.md) file.

[repo_link]: https://github.com/francescovallone/serinus
[documentation_link]: https://docs.serinus.app
[logo_white]: https://raw.githubusercontent.com/francescovallone/serinus/main/packages/serinus/assets/serinus-logo-long.png