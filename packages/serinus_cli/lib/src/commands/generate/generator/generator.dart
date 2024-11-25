import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:serinus_cli/src/commands/generate/builder.dart';
import 'package:serinus_cli/src/commands/generate/recase.dart';

class Generator {
  Generator({
    required this.outputDirectory,
    required this.entrypointFile,
    required this.itemName,
    required this.analyzer,
  });

  final Directory outputDirectory;
  final File? entrypointFile;
  final ReCase itemName;
  final SerinusAnalyzer analyzer;

  final DartEmitter emitter = DartEmitter(
    allocator: Allocator(),
    orderDirectives: true,
  );

  Future<void> replaceGetters(
    String filePath,
    String fileName,
    GeneratedElement element,
  ) async {
    if (entrypointFile != null) {
      final updates = await analyzer.analyze(
        outputDirectory.absolute.path,
        [
          element,
        ],
        entrypointFile!.path,
      );
      for (final update in updates) {
        final contents = entrypointFile!.readAsStringSync();
        String? replaced;
        if (update.oldValue != null) {
          replaced = contents.replaceFirst(
            update.oldValue!,
            update.newValue,
          );
        } else {
          final lastIndex = contents.lastIndexOf('}');
          replaced = contents.replaceRange(
            lastIndex,
            lastIndex,
            update.newValue,
          );
        }
        final entrypointUri = entrypointFile!.uri.toFilePath(
          windows: Platform.isWindows,
        );
        final outputUri = File('${outputDirectory.absolute.path}/$filePath')
            .uri
            .toFilePath(windows: Platform.isWindows);
        final sameFolder =
            (outputUri.split(Platform.pathSeparator)..removeLast()).join('/') ==
                (entrypointUri.split(Platform.pathSeparator)..removeLast())
                    .join('/');
        if (!replaced.contains(sameFolder ? fileName : filePath)) {
          final lastImport = replaced.lastIndexOf('import ');
          final lastImportSemiColon = replaced.indexOf(';', lastImport);
          replaced = replaced.replaceRange(
            lastImportSemiColon + 1,
            lastImportSemiColon + 1,
            "\nimport '${sameFolder ? fileName : filePath}';\n",
          );
        }
        entrypointFile!.writeAsStringSync(DartFormatter().format(replaced));
      }
    }
  }

  Future<String> generateController(GeneratedElement element) async {
    final newController = Library((b) {
      b.directives.add(Directive.import('package:serinus/serinus.dart'));
      b.body.add(
        Class((c) {
          c.name = '${itemName.getSentenceCase(separator: '')}Controller';
          c.constructors.add(
            Constructor((co) {
              co.initializers.add(
                Code(
                  "super(path: '/${itemName.getSnakeCase()}')",
                ),
              );
              co.body = Block.of([
                const Code(
                  "on(Route.get('/'), (RequestContext context) async => 'Hello, World!');",
                ),
                const Code(
                  "on(Route.post('/'), (RequestContext context) async => {'hello': 'world'});",
                ),
                const Code(
                  "on(Route.put('/'), (RequestContext context) async => {'hello': 'world'});",
                ),
                const Code(
                  "on(Route.delete('/'), (RequestContext context) async => {'hello': 'world'});",
                ),
              ]);
            }),
          );
          c.extend = refer('Controller');
        }),
      );
    });
    final fileName = '${itemName.getSnakeCase()}_controller.dart';
    final filePath = '${fileName.split('_').first}/$fileName';
    if (File(filePath).existsSync()) {
      return element.name;
    }
    await replaceGetters(filePath, fileName, element);
    File('${outputDirectory.absolute.path}/$filePath')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        DartFormatter().format(
          newController.accept(emitter).toString(),
        ),
      );
    return element.name;
  }

  Future<void> generateModule(GeneratedElement element) async {
    final emitter = DartEmitter(
      allocator: Allocator(),
      orderDirectives: true,
    );
    final newModule = Library((b) {
      b.directives.add(Directive.import('package:serinus/serinus.dart'));
      b.body.add(
        Class((c) {
          c.name = '${itemName.getSentenceCase(separator: '')}Module';
          c.constructors.add(
            Constructor((co) {
              co.initializers.add(
                const Code(
                  'super(imports: [], controllers: [], providers: [])',
                ),
              );
            }),
          );
          c.extend = refer('Module');
        }),
      );
    });
    final fileName = '${itemName.getSnakeCase()}_module.dart';
    final filePath = '${fileName.split('_').first}/$fileName';
    if (File(filePath).existsSync()) {
      return;
    }
    await replaceGetters(filePath, fileName, element);
    File('${outputDirectory.absolute.path}/$filePath')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        DartFormatter().format(
          newModule.accept(emitter).toString(),
        ),
      );
  }

  Future<String> generateProvider(GeneratedElement element) async {
    final emitter = DartEmitter(
      allocator: Allocator(),
      orderDirectives: true,
    );
    final newProvider = Library((b) {
      b.directives.add(Directive.import('package:serinus/serinus.dart'));
      b.body.add(
        Class((c) {
          c.name = '${itemName.getSentenceCase(separator: '')}Provider';
          c.constructors.add(
            Constructor((co) {}),
          );
          c.extend = refer('Provider');
        }),
      );
    });
    final fileName = '${itemName.getSnakeCase()}_provider.dart';
    final filePath = '${fileName.split('_').first}/$fileName';
    if (File(filePath).existsSync()) {
      return element.name;
    }
    await replaceGetters(filePath, fileName, element);
    File('${outputDirectory.absolute.path}/$filePath')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        DartFormatter().format(
          newProvider.accept(emitter).toString(),
        ),
      );
    return element.name;
  }
}
