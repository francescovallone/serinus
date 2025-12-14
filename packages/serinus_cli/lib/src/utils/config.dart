import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

class Config {

  const Config({
    required this.entrypoint,
    required this.name,
    this.models,
    this.client,
    this.watcher,
    this.dependencies = const {},
    this.devDependencies = const {},
  });

  factory Config.fromYaml(Map<String, dynamic> yaml) {
    return Config(
        entrypoint: yaml['entrypoint'] as String? ?? '',
        name: yaml['name'] as String? ?? '',
        models: yaml['models'] != null
            ? ModelsConfig.fromYaml((yaml['models'] as YamlMap).value)
            : null,
        client: yaml['client'] != null
            ? ClientConfig.fromYaml((yaml['client'] as YamlMap).value)
            : null,
        watcher: yaml['watcher'] != null
            ? WatcherConfig.fromYaml((yaml['watcher'] as YamlMap).value)
            : null,
        dependencies: Map<String, dynamic>.from(
            yaml['dependencies'] as Map<dynamic, dynamic>? ?? {}),
        devDependencies: Map<String, dynamic>.from(
            yaml['devDependencies'] as Map<dynamic, dynamic>? ?? {}));
  }
  final ModelsConfig? models;
  final ClientConfig? client;
  final WatcherConfig? watcher;
  final String? entrypoint;
  final String name;
  final Map<String, dynamic> dependencies;
  final Map<String, dynamic> devDependencies;
}

class WatcherConfig {

  const WatcherConfig({
    required this.whitelist,
  });

  factory WatcherConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return WatcherConfig(
      whitelist:
          List<String>.from((yaml['whitelist'] as YamlList?)?.value ?? []),
    );
  }
  final List<String> whitelist;
}

class ClientConfig {

  const ClientConfig({
    required this.verbose,
    required this.language,
    required this.httpClient,
    required this.output,
    required this.baseUrl,
  });

  factory ClientConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return ClientConfig(
      verbose: yaml['verbose'] as bool? ?? false,
      language: yaml['language'] as String? ?? 'Dart',
      httpClient: yaml['httpClient'] as String? ?? 'dio',
      output: yaml['output'] as String? ?? 'client',
      baseUrl: yaml['baseUrl'] as String? ?? 'http://localhost:3000',
    );
  }
  final bool verbose;
  final String language;
  final String httpClient;
  final String output;
  final String baseUrl;
}

class ModelsConfig {

  const ModelsConfig({
    required this.extensions,
    required this.deserializeKeywords,
    required this.serializeKeywords,
  });

  factory ModelsConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    return ModelsConfig(
      extensions:
          List<String>.from((yaml['extensions'] as YamlList?)?.value ?? []),
      deserializeKeywords:
          ((yaml['deserialize_keywords'] as YamlList?)?.value ?? [])
              .map((e) => DeserializeKeyword.fromYaml((e as YamlMap).value))
              .toList(),
      serializeKeywords:
          ((yaml['serialize_keywords'] as YamlList?)?.value ?? [])
              .map((e) => SerializeKeyword.fromYaml((e as YamlMap).value))
              .toList(),
    );
  }
  final List<String> extensions;
  final List<DeserializeKeyword> deserializeKeywords;
  final List<SerializeKeyword> serializeKeywords;
}

class DeserializeKeyword {

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
  final String keyword;
  final bool staticMethod;
}

class SerializeKeyword {

  const SerializeKeyword({
    required this.keyword,
  });

  factory SerializeKeyword.fromYaml(Map<dynamic, dynamic> yaml) {
    return SerializeKeyword(
      keyword: yaml['keyword'] as String? ?? '',
    );
  }
  final String keyword;
}

Future<Config> getProjectConfiguration(
  Logger logger, {
  bool deps = false,
}) async {
  final pubspec = File(path.join(Directory.current.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    throw const StdinException('No pubspec.yaml file found');
  }
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
  return Config.fromYaml({
    ...pubspecMap,
    'name': pubspecYaml['name'] as String? ?? 'serinus_app',
    if (deps) ...{
      'dependencies': pubspecYaml['dependencies'],
      'devDependencies': pubspecYaml['dev_dependencies'],
    }
  });
}
