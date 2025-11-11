import 'package:serinus_cli/src/utils/config.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('config should be parsed correctly', () {
    final config = Config.fromYaml({
      'entrypoint': 'lib/main.dart',
      'name': 'serinus_app',
      'models': YamlMap.wrap({
        'output': 'lib/models',
      }),
      'client': YamlMap.wrap({
        'http_client': 'dio',
      }),
      'watcher': YamlMap.wrap({
        'whitelist': ['lib/**.dart'],
      }),
      'dependencies': YamlMap.wrap({
        'serinus': YamlMap.wrap({
          'path': '../',
        }),
        'dio': '^5.0.0',
      }),
      'devDependencies': YamlMap.wrap({
        'build_runner': '^2.1.0',
        'serinus_cli': '^2.0.0',
      }),
    });
    expect(config.entrypoint, 'lib/main.dart');
    expect(config.name, 'serinus_app');
    expect(config.dependencies.length, 2);
    expect(config.devDependencies.length, 2);
    expect(config.dependencies['serinus'], isA<YamlMap>());
  });
}