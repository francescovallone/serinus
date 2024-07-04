import 'dart:io';

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:serinus_cli/src/commands/generate/builder.dart';
import 'package:serinus_cli/src/commands/generate/recase.dart';

Future<String> generateController(
  Directory outputDirectory,
  File? entrypointFile,
  GeneratedElement element,
  ReCase itemName,
  SerinusAnalyzer analyzer,
) async {
  final emitter = DartEmitter(
    allocator: Allocator(),
    orderDirectives: true,
  );
  final newModule = Library((b) {
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
                "on(Route.get('/'), (RequestContext context) async => Response.text('Hello, World!'));",
              ),
              const Code(
                "on(Route.post('/'), (RequestContext context) async => Response.json({'hello': 'world'}));",
              ),
              const Code(
                "on(Route.put('/'), (RequestContext context) async => Response.json({'hello': 'world'}));",
              ),
              const Code(
                "on(Route.delete('/'), (RequestContext context) async => Response.json({'hello': 'world'}));",
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
  if (entrypointFile != null) {
    final updates = await analyzer.analyze(
      outputDirectory.absolute.path,
      [
        element,
      ],
      entrypointFile.path,
    );
    for (final update in updates) {
      final contents = entrypointFile.readAsStringSync();
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
      final entrypointUri = entrypointFile.uri.toFilePath(
        windows: Platform.isWindows,
      );
      final outputUri = File('${outputDirectory.absolute.path}/$filePath')
          .uri
          .toFilePath(windows: Platform.isWindows);
      final sameFolder = (outputUri.split('/')..removeLast()).join('/') ==
          (entrypointUri.split('/')..removeLast()).join('/');
      if (!replaced.contains(sameFolder ? fileName : filePath)) {
        final lastImport = replaced.lastIndexOf('import ');
        final lastImportSemiColon = replaced.indexOf(';', lastImport);
        replaced = replaced.replaceRange(
          lastImportSemiColon + 1,
          lastImportSemiColon + 1,
          "\nimport '${sameFolder ? fileName : filePath}';\n",
        );
      }
      entrypointFile.writeAsStringSync(DartFormatter().format(replaced));
    }
  }
  File('${outputDirectory.absolute.path}/$filePath')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      DartFormatter().format(
        newModule.accept(emitter).toString(),
      ),
    );
  return element.name;
}

Future<void> generateModule(
  Directory outputDirectory,
  File? entrypointFile,
  GeneratedElement element,
  ReCase itemName,
  SerinusAnalyzer analyzer,
) async {
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
  if (entrypointFile != null) {
    final updates = await analyzer.analyze(
      outputDirectory.absolute.path,
      [
        element,
      ],
      entrypointFile.path,
    );
    for (final update in updates) {
      final contents = entrypointFile.readAsStringSync();
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
      final entrypointUri = entrypointFile.uri.toFilePath(
        windows: Platform.isWindows,
      );
      final outputUri = File('${outputDirectory.absolute.path}/$filePath')
          .uri
          .toFilePath(windows: Platform.isWindows);
      final sameFolder = (outputUri.split('/')..removeLast()).join('/') ==
          (entrypointUri.split('/')..removeLast()).join('/');
      if (!replaced.contains(sameFolder ? fileName : filePath)) {
        final lastImport = replaced.lastIndexOf('import ');
        final lastImportSemiColon = replaced.indexOf(';', lastImport);
        replaced = replaced.replaceRange(
          lastImportSemiColon + 1,
          lastImportSemiColon + 1,
          "\nimport '${sameFolder ? fileName : filePath}';\n",
        );
      }
      entrypointFile.writeAsStringSync(DartFormatter().format(replaced));
    }
  }
  File('${outputDirectory.absolute.path}/$filePath')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      DartFormatter().format(
        newModule.accept(emitter).toString(),
      ),
    );
}

Future<String> generateProvider(
  Directory outputDirectory,
  File? entrypointFile,
  GeneratedElement element,
  ReCase itemName,
  SerinusAnalyzer analyzer,
) async {
  final emitter = DartEmitter(
    allocator: Allocator(),
    orderDirectives: true,
  );
  final newModule = Library((b) {
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
  if (entrypointFile != null) {
    final updates = await analyzer.analyze(
      outputDirectory.absolute.path,
      [
        element,
      ],
      entrypointFile.path,
    );
    for (final update in updates) {
      final contents = entrypointFile.readAsStringSync();
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
      final entrypointUri = entrypointFile.uri.toFilePath(
        windows: Platform.isWindows,
      );
      final outputUri = File('${outputDirectory.absolute.path}/$filePath')
          .uri
          .toFilePath(windows: Platform.isWindows);
      final sameFolder = (outputUri.split('/')..removeLast()).join('/') ==
          (entrypointUri.split('/')..removeLast()).join('/');
      if (!replaced.contains(sameFolder ? fileName : filePath)) {
        final lastImport = replaced.lastIndexOf('import ');
        final lastImportSemiColon = replaced.indexOf(';', lastImport);
        replaced = replaced.replaceRange(
          lastImportSemiColon + 1,
          lastImportSemiColon + 1,
          "\nimport '${sameFolder ? fileName : filePath}';\n",
        );
      }
      entrypointFile.writeAsStringSync(DartFormatter().format(replaced));
    }
  }
  File('${outputDirectory.absolute.path}/$filePath')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      DartFormatter().format(
        newModule.accept(emitter).toString(),
      ),
    );
  return element.name;
}
