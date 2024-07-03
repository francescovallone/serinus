import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/dart/analysis/results.dart';
//ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart';

Future<List<FileUpdates>> analyze(String path, List<GeneratedElement> elements, String? entrypointFile) async {
  final directory = Directory(path);
  final List<FileUpdates> updates = [];
  final collection = AnalysisContextCollection(includedPaths: [directory.path], resourceProvider: PhysicalResourceProvider.INSTANCE);
  for (final context in collection.contexts) {
    for (final file in context.contextRoot.analyzedFiles()) {
      if(entrypointFile != null && !file.contains(entrypointFile)) {
        continue;
      }
      if (!file.endsWith('.dart')) {
        continue;
      }
      final resolvedUnit = await context.currentSession.getUnitElement(file);
      final unit = resolvedUnit as UnitElementResult;
      // final visitor = _ClassVisitor();
      final element = unit.element;
      final classes = element.classes;
      for (final clazz in classes) {
        print(clazz.name);
        final superclass = clazz.supertype?.element.name;
        // clazz.accept(visitor);
        final callForImports = elements.where((e) => e.type == ElementType.module);
        if (callForImports.isNotEmpty && superclass == 'Module') {
          String imports = callForImports.map((e) => e.source).join(',\n');
          final startOldValue = clazz.source.contents.data.indexOf('imports => ');
          String? oldValue = startOldValue > -1 
              ? clazz.source.contents.data.substring(
                startOldValue, 
              ).trim()
              : null;
          if(oldValue != null && !oldValue.startsWith('[')) {
            oldValue = oldValue.substring(startOldValue, oldValue.indexOf(';') + 1);
            imports = '''[
              ...$oldValue,
              $imports,
            ];\n''';
          }
          updates.add(FileUpdates(
            newValue: imports,
            oldValue: oldValue,
          ),);
        }
      }
    }
  }
  return updates;
}

enum ElementType implements Comparable<ElementType>{
  controller('controllers'),
  module('imports'),
  provider('providers');

  final String keyword;

  const ElementType(this.keyword);

  @override
  int compareTo(ElementType other) => index;
}

class GeneratedElement {

  final ElementType type;
  final String name;
  final String source;

  const GeneratedElement({
    required this.type,
    required this.name,
    required this.source,
  });

}

class FileUpdates {

  final String newValue;
  final String? oldValue;

  const FileUpdates({
    required this.newValue,
    this.oldValue,
  });

}
