
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:serinus_cli/src/commands/generate/generate_client/controllers_analyzer.dart';
import 'package:serinus_cli/src/utils/config.dart';

/// {@template generate_command}
///
/// `serinus_cli sample`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class GenerateClientCommand extends Command<int> {
  /// {@macro generate_command}
  GenerateClientCommand({
    Logger? logger,
  }) : _logger = logger;

  /// [ArgResults] used for testing purposes only.
  @visibleForTesting
  ArgResults? testArgResults;

  /// [String] used for testing purposes only.
  @visibleForTesting
  String? testUsage;

  @override
  ArgResults get argResults => super.argResults ?? testArgResults!;

  String get usageString => testUsage ?? usage;

  @override
  String get description => 'Generate the client for your Serinus application';

  @override
  String get name => 'client';

  final Logger? _logger;

  @override
  Future<int> run() async {
    final config = await getProjectConfiguration(_logger!);
    if (config.length == 1 && config.containsKey('error')) {
      return config['error'] as int;
    }
    final files = await _recursiveGetFiles(
      Directory.current,
      config,
    );
    final analyzer = ControllersAnalyzer();
    await analyzer.analyze(
      files,
      config,
      _logger!,
    );
    return ExitCode.success.code;
  }

  Future<List<File>> _recursiveGetFiles(
    Directory dir, 
    Map<String, dynamic> config,
  ) async {
    final files = <File>[];
    final entities = dir.listSync();
    for (final entity in entities) {
      if (entity is File) {
        if(!entity.path.endsWith('.dart')) {
          continue;
        }
        final content = entity.readAsStringSync();
        if (
          containController(content) || containRoute(content)
        ) {
          files.add(entity);
        }
      } else if (entity is Directory) {
        files.addAll(await _recursiveGetFiles(
          entity, config),);
      }
    }
    return files;
  }

  bool containController(String content) {
    return content.contains('class') && 
          content.contains('extends Controller');
  }

  bool containRoute(String content) {
    return content.contains('class') &&
          content.contains('extends Route');
  }
 
}
