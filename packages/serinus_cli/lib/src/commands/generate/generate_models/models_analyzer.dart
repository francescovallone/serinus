import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:serinus_cli/src/commands/generate/generate_models/generate_models_command.dart';

class ModelsAnalyzer {
  Future<List<Model>> analyze(
    List<File> files,
    Map<String, dynamic> config,
    List<SerializeKeyword> serializeKeywords,
    List<DeserializeKeyword> deserializeKeywords,
  ) async {
    final collection = AnalysisContextCollection(
      includedPaths: files.map((file) => file.path).toList(),
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    final models = <Model>[];
    for (final context in collection.contexts) {
      for (final file in context.contextRoot.analyzedFiles()) {
        if (!file.endsWith('.dart')) {
          continue;
        }
        final unitElement = await context.currentSession.getUnitElement(file);
        final unit = unitElement as UnitElementResult;
        final element = unit.fragment.element;
        final classes = element.classes;
        for (final clazz in classes) {
          final name = clazz.name;
          final isDartMappable = clazz.mixins
              .where(
                (e) => e.getDisplayString().contains('${name}Mappable'),
              )
              .isNotEmpty;
          final methods = clazz.methods;
          final constructors = clazz.constructors;
          var hasFromJson = false;
          var hasToJson = false;
          var fromJson = '';
          var toJson = '';
          if (isDartMappable) {
            hasToJson = true;
            hasFromJson = true;
            fromJson = '${name}Mapper.fromMap';
            toJson = 'toMap';
          }
          for (final c in constructors) {
            if (c.name == null) {
              continue;
            }
            if (!hasFromJson) {
              for (final s in deserializeKeywords) {
                if (c.name!.contains(s.name) && !s.isStatic && !c.isStatic) {
                  hasFromJson = true;
                  fromJson = '$name.${c.name}';
                  break;
                }
              }
            }
          }
          for (final m in methods) {
            if (m.name == null) {
              continue;
            }
            if (!hasFromJson) {
              for (final s in deserializeKeywords) {
                if (m.name!.contains(s.name) && s.isStatic && m.isStatic) {
                  hasFromJson = true;
                  fromJson = '$name.${m.name}';
                  break;
                }
              }
            }
            if (!hasToJson) {
              for (final s in serializeKeywords) {
                if (m.name!.contains(s.name)) {
                  hasToJson = true;
                  toJson = m.name!;
                  break;
                }
              }
            }
          }
          final path = file.split(Platform.pathSeparator);
          final libIndex = path.indexOf('lib');
          path.removeRange(0, libIndex + 1);
          if ((hasToJson || hasFromJson) && name != null) {
            models.add(
              Model(
                filename: path.join('/'),
                name: name,
                hasFromJson: hasFromJson,
                hasToJson: hasToJson,
                fromJson: fromJson,
                toJson: toJson,
                isDartMappable: isDartMappable,
              ),
            );
          }
        }
      }
    }
    return models;
  }
}

class Model {
  const Model({
    required this.filename,
    required this.name,
    required this.hasFromJson,
    required this.hasToJson,
    required this.fromJson,
    required this.toJson,
    this.isDartMappable = false,
  });

  final String filename;
  final String name;
  final bool hasFromJson;
  final bool hasToJson;
  final String fromJson;
  final String toJson;
  final bool isDartMappable;

  @override
  String toString() {
    return '''Model{filename: $filename, name: $name, hasFromJson: $hasFromJson, hasToJson: $hasToJson, fromJson: $fromJson, toJson: $toJson, isDartMappable: $isDartMappable}''';
  }
}
