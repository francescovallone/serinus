// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
//ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart';

class SerinusAnalyzer {
  Future<List<FileUpdates>> analyze(
    String path,
    List<GeneratedElement> elements,
    String? entrypointFile,
  ) async {
    final directory = Directory(path);
    final updates = <FileUpdates>[];
    final collection = AnalysisContextCollection(
      includedPaths: [directory.path],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    for (final context in collection.contexts) {
      for (final file in context.contextRoot.analyzedFiles()) {
        if (entrypointFile != null && !file.contains(entrypointFile)) {
          continue;
        }
        if (!file.endsWith('.dart')) {
          continue;
        }
        final unitElement = await context.currentSession.getUnitElement(file);
        final unit = unitElement as UnitElementResult;
        final resolvedUnit = await context.currentSession.getResolvedUnit(file);
        final resolved = resolvedUnit as ResolvedUnitResult;
        final directivesImports =
            resolved.unit.directives.whereType<ImportDirective>().toSet();
        final parts =
            resolved.unit.directives.whereType<PartDirective>().toSet();
        final partOf =
            resolved.unit.directives.whereType<PartOfDirective>().firstOrNull;

        // final visitor = _ClassVisitor();
        final element = unit.fragment.element;
        final classes = element.classes;
        for (final clazz in classes) {
          final superclass = clazz.supertype?.element.name;
          final callForImports = elements.where(
            (e) => e.type == ElementType.module,
          );
          final source =
              clazz.firstFragment.enclosingFragment?.source.contents.data;
          if (callForImports.isNotEmpty && superclass == 'Module') {
            updates.add(
              getUpdates(
                directivesImports,
                parts,
                partOf,
                callForImports,
                'Module',
                'imports',
                source ?? '',
              ),
            );
          }
          final callForControllers = elements.where(
            (e) => e.type == ElementType.controller,
          );
          if (callForControllers.isNotEmpty && superclass == 'Module') {
            updates.add(
              getUpdates(
                directivesImports,
                parts,
                partOf,
                callForControllers,
                'Controller',
                'controllers',
                source ?? '',
              ),
            );
          }
          final callForProviders = elements.where(
            (e) => e.type == ElementType.provider,
          );
          if (callForProviders.isNotEmpty && superclass == 'Module') {
            updates.add(
              getUpdates(
                directivesImports,
                parts,
                partOf,
                callForProviders,
                'Provider',
                'providers',
                source ?? '',
              ),
            );
          }
        }
      }
    }
    return updates;
  }

  FileUpdates getUpdates(
    Iterable<ImportDirective> imports,
    Iterable<PartDirective> parts,
    PartOfDirective? partOf,
    Iterable<GeneratedElement> elements,
    String type,
    String getter,
    String content,
  ) {
    final elementsInEntrypoint = getListInEntrypoint(type, getter);
    final elementsStringified = elements.map((e) => e.name).join(',\n');
    final getterPattern = RegExp(
      '(?:@override\\s+)?List<$type>\\s+get\\s+$getter\\s*=>\\s*\\[[\\s\\S]*?\\];',
      multiLine: true,
    );
    final getterMatch = getterPattern.firstMatch(content);
    final oldValue = getterMatch?.group(0);

    String newValue;
    if (oldValue == null) {
      // ignore: leading_newlines_in_multiline_strings
      newValue = '''
          
          @override
          $elementsInEntrypoint [
            ...super.$getter,
            $elementsStringified,
          ];\n''';
    } else {
      final missingElements = elements
          .where((element) => !oldValue.contains(element.name))
          .map((element) => element.name)
          .toList();

      if (missingElements.isEmpty) {
        newValue = oldValue;
      } else {
        final replacedOldValue = oldValue.replaceFirst('];', '');
        newValue = '''

              $replacedOldValue
              ${missingElements.join(',\n')},
            ];\n''';
      }
    }
    return FileUpdates(
      newValue: newValue,
      oldValue: oldValue,
      imports: imports
          .map(
            (e) => "import '${e.uri.stringValue ?? ''}';",
          )
          .toSet(),
      parts: parts
          .map(
            (e) => "parts '${e.uri.stringValue ?? ''}';",
          )
          .toSet(),
      partOf: partOf != null ? "part of '${partOf.uri?.stringValue}'" : null,
    );
  }
}

enum ElementType implements Comparable<ElementType> {
  controller('controllers'),
  module('imports'),
  provider('providers');

  const ElementType(this.keyword);

  final String keyword;

  @override
  int compareTo(ElementType other) => index;
}

class GeneratedElement {
  const GeneratedElement({
    required this.type,
    required this.name,
  });

  final ElementType type;
  final String name;
}

class FileUpdates {
  const FileUpdates({
    required this.newValue,
    required this.imports,
    required this.parts,
    this.partOf,
    this.oldValue,
  });

  final String newValue;
  final String? oldValue;
  final Iterable<String> imports;
  final Iterable<String> parts;
  final String? partOf;
}

String getListInEntrypoint(String type, String getter) {
  return 'List<$type> get $getter =>';
}
