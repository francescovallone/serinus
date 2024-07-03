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
        if(entrypointFile != null && !file.contains(entrypointFile)) {
          continue;
        }
        if (!file.endsWith('.dart')) {
          continue;
        }
        final unitElement = await context.currentSession.getUnitElement(file);
        final unit = unitElement as UnitElementResult;
        final resolvedUnit = await context.currentSession.getResolvedUnit(file);
        final resolved = resolvedUnit as ResolvedUnitResult;
        final directivesImports = resolved.unit.directives
          .whereType<ImportDirective>().toSet();
        final parts = resolved.unit.directives
          .whereType<PartDirective>().toSet();
        final partOf = resolved.unit.directives
          .whereType<PartOfDirective>().firstOrNull;

        
        // final visitor = _ClassVisitor();
        final element = unit.element;
        final classes = element.classes;
        for (final clazz in classes) {
          final superclass = clazz.supertype?.element.name;
          final callForImports = elements.where(
            (e) => e.type == ElementType.module,);
          if (callForImports.isNotEmpty && superclass == 'Module') {
            updates.add(getUpdates(
              directivesImports, 
              parts, 
              partOf,
              callForImports,
              'Module',
              'imports',
              clazz.source.contents.data,
            ),);
          }
          final callForControllers = elements.where(
            (e) => e.type == ElementType.controller,);
          if(callForControllers.isNotEmpty && superclass == 'Module') {
            updates.add(getUpdates(
              directivesImports, 
              parts, 
              partOf,
              callForControllers,
              'Controller',
              'controllers',
              clazz.source.contents.data,
            ),);
          }
          final callForProviders = elements.where(
            (e) => e.type == ElementType.provider,);
          if(callForProviders.isNotEmpty && superclass == 'Module') {
            updates.add(getUpdates(
              directivesImports, 
              parts, 
              partOf,
              callForProviders,
              'Provider',
              'providers',
              clazz.source.contents.data,
            ),);
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
    var elementsStringified = elements.map((e) => e.name).join(',\n');
    final startOldValue = calculateStartIndex(content, elementsInEntrypoint,);
    var oldValue = startOldValue > -1 
        ? content.substring(
          startOldValue, 
        ).trim()
        : null;
    if(oldValue != null) {
      oldValue = oldValue
        .substring(0, oldValue.indexOf(';') + 1);
      if(!oldValue.contains('[')) {
        // ignore: leading_newlines_in_multiline_strings
        elementsStringified = '''
          
          @override
          $elementsInEntrypoint [
          ...super.$getter,
          $elementsStringified,
        ];\n''';
      }else{
        // ignore: leading_newlines_in_multiline_strings
        if(!oldValue.contains(elementsStringified)){
          final replacedOldValue = oldValue.replaceFirst('];', '');
          elementsStringified = '''

              $replacedOldValue
              $elementsStringified,
            ];\n''';
          }else{
            elementsStringified = oldValue;
          }
        }
      }else{
        // ignore: leading_newlines_in_multiline_strings
        elementsStringified = '''
          
          @override
          $elementsInEntrypoint [
            ...super.$getter,
            $elementsStringified,
          ];\n''';
      }
      return FileUpdates(
        newValue: elementsStringified,
        oldValue: oldValue,
        imports: imports.map(
          (e) => "import '${e.uri.stringValue ?? ''}';",).toSet(),
        parts: parts.map(
          (e) => "parts '${e.uri.stringValue ?? ''}';",).toSet(),
        partOf: partOf != null 
          ? "part of '${partOf.uri?.stringValue}'" : null,
      );
  }

}

enum ElementType implements Comparable<ElementType>{
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

String getListInEntrypoint(String type, String getter){
  return 'List<$type> get $getter =>';
}

int calculateStartIndex(String data, String keyword){
  return data.indexOf(
    keyword,
  ) - '@override'.length - [13, 10].length * 2;
}
