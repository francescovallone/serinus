import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

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
    final pubspec = File(path.join(Directory.current.path, 'pubspec.yaml'));
    final progress = _logger.progress('Creating Dockerfile...');
    final port = argResults!['port'].toString();
    final output = argResults!['output'].toString();
    if (!pubspec.existsSync()) {
      _logger.err('No pubspec.yaml file found');
      progress.fail('Failed to create Dockerfile');
      return ExitCode.noInput.code;
    }
    final configFile = File(path.join(Directory.current.path, 'config.yaml'));
    var entrypoint = '';
    var content = <String, dynamic>{};
    final pubspecContent = await pubspec.readAsString();
    content = Map<String, dynamic>.from(loadYaml(pubspecContent) as Map);
    if (!configFile.existsSync()) {
      _logger.warn(
        'No config.yaml file found, using pubspec.yaml to get entrypoint',
      );
      content['name'] = content['name'] as String;
      entrypoint = 'bin/${content['name']}.dart';
    } else {
      final configContent = await configFile.readAsString();
      final content = Map<String, dynamic>.from(loadYaml(configContent) as Map);
      entrypoint = content['entrypoint'] as String;
    }
    // final dockerFileContent = dockerFileFromRepository(entrypoint, output, port);
    File(path.join(Directory.current.path, 'Dockerfile'))
        .writeAsStringSync(dockerFile(entrypoint, output, port));
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
