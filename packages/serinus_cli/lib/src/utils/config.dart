import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class Config {

  final ModelsConfig? models;
  final ClientConfig? client;
  final WatcherConfig? watcher;
  final String? entrypoint;
  final String name;
  final Map<String, String> dependencies;

  const Config({
    required this.entrypoint,
    required this.name,
    this.models,
    this.client,
    this.watcher,
    this.dependencies = const {}
  });

  factory Config.fromYaml(Map<String, dynamic> yaml) {
    return Config(
      entrypoint: yaml['entrypoint'] as String? ?? '',
      name: yaml['name'] as String? ?? '',
      models: yaml['models'] != null ? ModelsConfig.fromYaml((yaml['models'] as YamlMap).value) : null,
      client: yaml['client'] != null ? ClientConfig.fromYaml((yaml['client'] as YamlMap).value) : null,
      watcher: yaml['watcher'] != null ? WatcherConfig.fromYaml((yaml['watcher'] as YamlMap).value) : null,
      dependencies: Map<String, String>.from(yaml['dependencies'] as Map<dynamic, dynamic>? ?? {}),
    );
  }
}

class WatcherConfig {

  final List<String> whitelist;

  const WatcherConfig({
    required this.whitelist,
  });

  factory WatcherConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return WatcherConfig(
      whitelist: List<String>.from((yaml['whitelist'] as YamlList?)?.value ?? []),
    );
  }

}

class ClientConfig {

  final bool verbose;
  final String language;
  final String httpClient;

  const ClientConfig({
    required this.verbose,
    required this.language,
    required this.httpClient,
  });

  factory ClientConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return ClientConfig(
      verbose: yaml['verbose'] as bool? ?? false,
      language: yaml['language'] as String? ?? 'Dart',
      httpClient: yaml['httpClient'] as String? ?? 'dio',
    );
  }

}

class ModelsConfig {

  final List<String> extensions;
  final List<DeserializeKeyword> deserializeKeywords;
  final List<SerializeKeyword> serializeKeywords;

  const ModelsConfig({
    required this.extensions,
    required this.deserializeKeywords,
    required this.serializeKeywords,
  });

  factory ModelsConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return ModelsConfig(
      extensions: List<String>.from((yaml['extensions'] as YamlList?)?.value ?? []),
      deserializeKeywords: ((yaml['deserialize_keywords'] as YamlList?)?.value ?? [])
          .map((e) => DeserializeKeyword.fromYaml((e as YamlMap).value))
          .toList(),
      serializeKeywords: ((yaml['serialize_keywords'] as YamlList?)?.value ?? [])
          .map((e) => SerializeKeyword.fromYaml((e as YamlMap).value))
          .toList(),
    );
  }

}

class DeserializeKeyword {
  final String keyword;
  final bool staticMethod;

  const DeserializeKeyword({
    required this.keyword,
    this.staticMethod = false,
  });

  factory DeserializeKeyword.fromYaml(Map<dynamic, dynamic> yaml) {
    return DeserializeKeyword(
      keyword: yaml['keyword'] as String? ?? '',
      staticMethod: yaml['static_method'] as bool? ?? false,
    );
  }
}

class SerializeKeyword {
  final String keyword;

  const SerializeKeyword({
    required this.keyword,
  });

  factory SerializeKeyword.fromYaml(Map<dynamic, dynamic> yaml) {
    return SerializeKeyword(
      keyword: yaml['keyword'] as String? ?? '',
    );
  }
}

Future<Config> getProjectConfiguration(
  Logger logger, {
  bool deps = false,
}) async {
  final pubspec = File(path.join(Directory.current.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    throw StdinException('No pubspec.yaml file found');
  }
  final configFile = File(path.join(Directory.current.path, 'config.yaml'));
  final pubspecContent = await pubspec.readAsString();
  final pubspecYaml = loadYaml(pubspecContent) as YamlMap;
  final pubspecMap = Map<String, dynamic>.from(
    Map<dynamic, dynamic>.fromEntries(pubspecYaml.entries)['serinus'] as Map? ??
        {},
  );
  if (pubspecMap.isEmpty || !pubspecMap.containsKey('entrypoint')) {
    pubspecMap['entrypoint'] =
        'bin/${pubspecYaml['name'] as String? ?? 'serinus_app'}.dart';
  }
  if (configFile.existsSync()) {
    logger
      ..warn('The file config.yaml is deprecated.')
      ..warn(
        'Go to https://serinus.app/ to learn more about the new configuration approaches.',
      );
    final configContent = await configFile.readAsString();
    final result = {
      ...Map<String, dynamic>.from(loadYaml(configContent) as Map),
      ...pubspecMap,
      'name': pubspecYaml['name'] as String? ?? 'serinus_app',
      if (deps) 'dependencies': pubspecYaml['dependencies'],
    };
    return Config.fromYaml(result);
  }
  return Config.fromYaml({
    ...pubspecMap,
    'name': pubspecYaml['name'] as String? ?? 'serinus_app',
    if (deps) 'dependencies': pubspecYaml['dependencies'],
  });
}
