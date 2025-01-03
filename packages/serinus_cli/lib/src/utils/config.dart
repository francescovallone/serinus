import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

Future<Map<String, dynamic>> getProjectConfiguration(Logger logger,
    {bool deps = false}) async {
  final pubspec = File(path.join(Directory.current.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    logger.err('No pubspec.yaml file found');
    return {
      'error': ExitCode.noInput.code,
    };
  }
  final configFile = File(path.join(Directory.current.path, 'config.yaml'));
  final pubspecContent = await pubspec.readAsString();
  final pubspecYaml = loadYaml(pubspecContent) as YamlMap;
  final pubspecMap = Map<String, dynamic>.from(
    Map<dynamic, dynamic>.fromEntries(pubspecYaml.entries)['serinus'] as Map? ??
        {},
  );
  if (pubspecMap.isEmpty) {
    logger.warn('No serinus configuration found in pubspec.yaml');
    pubspecMap['entrypoint'] =
        'bin/${pubspecYaml['name'] as String? ?? 'serinus_app'}.dart';
  }
  if (configFile.existsSync()) {
    logger
      ..warn('The file config.yaml is deprecated.')
      ..warn(
        'Go to https://serinus.app/foundations/configuration to learn more about the new configuration approach.',
      );
    final configContent = await configFile.readAsString();
    final result = {
      ...Map<String, dynamic>.from(loadYaml(configContent) as Map),
      ...pubspecMap,
      'name': pubspecYaml['name'] as String? ?? 'serinus_app',
      if (deps) 'dependencies': pubspecYaml['dependencies'],
    };
    return result;
  }
  return {
    ...pubspecMap,
    'name': pubspecYaml['name'] as String? ?? 'serinus_app',
    if (deps) 'dependencies': pubspecYaml['dependencies'],
  };
}
