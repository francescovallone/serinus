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

  int? _findModuleClassClosingBraceIndex(String source) {
    final moduleClassMatch = RegExp(
      r'class\s+\w+\s+extends\s+Module\s*\{',
      multiLine: true,
    ).firstMatch(source);
    if (moduleClassMatch == null) {
      return null;
    }

    final classStartBraceIndex = source.indexOf('{', moduleClassMatch.start);
    if (classStartBraceIndex == -1) {
      return null;
    }

    var depth = 0;
    for (var index = classStartBraceIndex; index < source.length; index++) {
      final char = source[index];
      if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) {
          return index;
        }
      }
    }

    return null;
  }

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
          final classClosingBraceIndex =
              _findModuleClassClosingBraceIndex(contents);
          final lastIndex = classClosingBraceIndex ?? contents.lastIndexOf('}');
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
        entrypointFile!.writeAsStringSync(
          DartFormatter(
            languageVersion: DartFormatter.latestShortStyleLanguageVersion,
          ).format(replaced),
        );
      }
    }
  }

  Future<({String elementName, bool generated})> generateController(
    GeneratedElement element, {
    bool overwrite = false,
  }) async {
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
    if (File('${outputDirectory.absolute.path}/$filePath').existsSync() &&
        !overwrite) {
      return (
        elementName: element.name,
        generated: false,
      );
    }
    await replaceGetters(filePath, fileName, element);
    File('${outputDirectory.absolute.path}/$filePath')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        DartFormatter(
          languageVersion: DartFormatter.latestShortStyleLanguageVersion,
        ).format(
          newController.accept(emitter).toString(),
        ),
      );
    return (
      elementName: element.name,
      generated: true,
    );
  }

  Future<bool> generateModule(
    GeneratedElement element, {
    bool overwrite = false,
  }) async {
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
    if (File('${outputDirectory.absolute.path}/$filePath').existsSync() &&
        !overwrite) {
      return false;
    }
    await replaceGetters(filePath, fileName, element);
    File('${outputDirectory.absolute.path}/$filePath')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        DartFormatter(
          languageVersion: DartFormatter.latestShortStyleLanguageVersion,
        ).format(
          newModule.accept(emitter).toString(),
        ),
      );
    return true;
  }

  Future<({String elementName, bool generated})> generateProvider(
      GeneratedElement element,
      {bool overwrite = false}) async {
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
    if (File('${outputDirectory.absolute.path}/$filePath').existsSync() &&
        !overwrite) {
      return (
        elementName: element.name,
        generated: false,
      );
    }
    await replaceGetters(filePath, fileName, element);
    File('${outputDirectory.absolute.path}/$filePath')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        DartFormatter(
          languageVersion: DartFormatter.latestShortStyleLanguageVersion,
        ).format(
          newProvider.accept(emitter).toString(),
        ),
      );
    return (
      elementName: element.name,
      generated: true,
    );
  }
}
