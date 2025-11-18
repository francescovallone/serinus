import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:openapi_types/open_api_parser.dart';
import 'package:openapi_types/openapi_types.dart';
import 'package:serinus_cli/src/utils/config.dart';

/// {@template generate_command}
///
/// `serinus generate from-spec <spec-file>`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class GenerateFromSpecCommand extends Command<int> {
  /// {@macro generate_command}
  GenerateFromSpecCommand({
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
  String get description => 'Generate Serinus stubs from an OpenAPI specification file';

  @override
  String get name => 'from-spec';

  final Logger? _logger;

  @override
  Future<int> run([String? output]) async {
    final Config config;
    try {
      config = await getProjectConfiguration(_logger!, deps: true);
    } catch (e) {
      _logger?.err('Failed to load project configuration: $e');
      return ExitCode.config.code;
    }
    final result = await generateStubs(config);
    return result;
  }

  File get _specFile {
    final rest = argResults.rest;
    _validateSpecFile(rest);
    return File(rest.first);
  }

  void _validateSpecFile(List<String> rest) {
    if (rest.isEmpty) {
      _logger?.err('No specification file provided.');
      throw UsageException(
        'No specification file provided.',
        usage,
      );
    }
    final specFile = File(rest.first);
    if (!specFile.existsSync()) {
      _logger?.err('Specification file does not exist: ${specFile.path}');
      throw UsageException(
        'Specification file does not exist: ${specFile.path}',
        usage,
      );
    }
    final allowedExtensions = ['.yaml', '.yml', '.json'];
    if (!allowedExtensions.any((ext) => specFile.path.endsWith(ext))) {
      _logger?.err(
        'Invalid specification file format. Allowed formats are: ${allowedExtensions.join(', ')}',
      );
      throw UsageException(
        'Invalid specification file format. Allowed formats are: ${allowedExtensions.join(', ')}',
        usage,
      );
    }
  }

  Future<int> generateStubs(
    Config config,
  ) async {
    final progress = _logger?.progress(
      'Generating stubs from OpenAPI specification...',
    );
    final specFile = _specFile;
    final parser = OpenApiParser();
    final isJson = specFile.path.endsWith('.json');
    final document = isJson 
      ? parser.parseFromJson(specFile.path) 
      : parser.parseFromYaml(specFile.path);
    final version = document.info.version;
    if (document is DocumentV2) {
      _logger?.info('OpenAPI version 2 detected. Generating stubs for OpenAPI v2...');
      // _generateForV2(document as DocumentV2, config);
    } else if (document is DocumentV3) {
      _logger?.info('OpenAPI version 3 detected. Generating stubs for OpenAPI v3...');
      _generateForV3(document, config);
    } else if (document is DocumentV31) {
      _logger?.info('OpenAPI version 3.1 detected. Generating stubs for OpenAPI v3.1...');
      // _generateForV31(document as DocumentV31, config);
    } else {
      progress?.fail('Unsupported OpenAPI version: $version');
      return ExitCode.config.code;
    }
  }

  void _generateForV3(
    DocumentV3 document,
    Config config,
  ) {
    final tags = 
  }

  List<String> _groupByTags()

}
