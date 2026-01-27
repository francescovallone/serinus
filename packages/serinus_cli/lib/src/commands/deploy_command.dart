import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:serinus_cli/src/utils/config.dart';

/// {@template update_command}
/// A command which updates the CLI.
/// {@endtemplate}
class DeployCommand extends Command<int> {
  /// {@macro update_command}
  DeployCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'port',
        help: 'The port to expose the application on.',
        defaultsTo: '3000',
      )
      ..addOption(
        'output',
        help: 'The name of the output file.',
        defaultsTo: 'app',
      );
  }

  final Logger _logger;

  @override
  String get description => 'Create a Dockerfile to deploy the application.';

  static const String commandName = 'deploy';

  @override
  String get name => commandName;

  @override
  Future<int> run() async {
    final progress = _logger.progress('Creating Dockerfile...');
    final port = argResults!['port'].toString();
    final output = argResults!['output'].toString();
    final Config config;
    try {
      config = await getProjectConfiguration(_logger, deps: true);
    } catch (e) {
      _logger.err('Failed to load project configuration: $e');
      return ExitCode.config.code;
    }
    // final dockerFileContent = dockerFileFromRepository(entrypoint, output, port);
    File(path.join(Directory.current.path, 'Dockerfile'))
        .writeAsStringSync(dockerFile(config.entrypoint ?? '', output, port));
    progress.complete('Dockerfile created');
    return ExitCode.success.code;
  }

  Future<String?> dockerFileFromRepository(
    String entrypoint,
    String output,
    String port,
  ) async {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse(
          'https://raw.githubusercontent.com/francescovallone/serinus/refs/heads/main/utils/Dockerfile.base'),
    );
    final response = await request.close();
    if (response.statusCode != 200) {
      _logger.err(
        'Failed to fetch Dockerfile from repository fallback to cli version',
      );
      return null;
    }
    final responseBody = await response.transform(utf8.decoder).join();
    final dockerFileContent = responseBody
        .replaceAll('{{$entrypoint}}', entrypoint)
        .replaceAll('{{$output}}', output)
        .replaceAll('{{$port}}', port);

    return dockerFileContent;
  }

  String dockerFile(
    String entrypoint,
    String output,
    String port,
  ) =>
      '''
FROM dart:latest AS build

WORKDIR /app

COPY . ./
COPY pubspec.* ./
RUN dart pub get
COPY . .

RUN dart pub get --offline
RUN mkdir -p dist
RUN dart compile exe $entrypoint -o dist/$output

FROM scratch
EXPOSE $port
COPY --from=build /runtime/ /
COPY --from=build /app/dist/$output /app/bin/

CMD ["/app/bin/$output"]
  ''';
}
