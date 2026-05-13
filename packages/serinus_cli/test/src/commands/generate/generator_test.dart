import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:serinus_cli/src/commands/generate/builder.dart';
import 'package:serinus_cli/src/commands/generate/generator/generator.dart';
import 'package:serinus_cli/src/commands/generate/recase.dart';
import 'package:test/test.dart';

void main() {
  group('Generator', () {
    late Directory tempDir;
    late Generator generator;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('serinus_cli_generator_');
      generator = Generator(
        outputDirectory: Directory(path.join(tempDir.path, 'lib')),
        entrypointFile: null,
        itemName: ReCase('sample'),
        analyzer: SerinusAnalyzer(),
      );
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('generates controller using the current controller constructor',
        () async {
      final result = await generator.generateController(
        const GeneratedElement(
          type: ElementType.controller,
          name: 'SampleController()',
        ),
      );

      expect(result.generated, isTrue);

      final content = File(
        path.join(tempDir.path, 'lib', 'sample', 'sample_controller.dart'),
      ).readAsStringSync();

      expect(content, contains("SampleController() : super('/sample')"));
      expect(content, isNot(contains('super(path:')));
      expect(content, contains("on(Route.get('/'), (RequestContext context)"));
    });

    test('generates module and provider scaffolds', () async {
      final generatedModule = await generator.generateModule(
        const GeneratedElement(
          type: ElementType.module,
          name: 'SampleModule()',
        ),
      );
      final generatedProvider = await generator.generateProvider(
        const GeneratedElement(
          type: ElementType.provider,
          name: 'SampleProvider()',
        ),
      );

      expect(generatedModule, isTrue);
      expect(generatedProvider.generated, isTrue);

      final moduleContent = File(
        path.join(tempDir.path, 'lib', 'sample', 'sample_module.dart'),
      ).readAsStringSync();
      final providerContent = File(
        path.join(tempDir.path, 'lib', 'sample', 'sample_provider.dart'),
      ).readAsStringSync();

      expect(moduleContent, contains('class SampleModule extends Module'));
      expect(moduleContent,
          contains('super(imports: [], controllers: [], providers: [])'));
      expect(
          providerContent, contains('class SampleProvider extends Provider'));
      expect(providerContent, contains('SampleProvider();'));
    });
  });
}
