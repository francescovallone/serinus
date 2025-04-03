/// The [Edge] class is an abstract class that represents an edge in the inspector.
class Edge {

  /// The id of this edge. This is used to identify the edge in the tree.
  final String id;

  /// The source of this edge. This is used to identify the source node in the tree.
  final String source;

  /// The target of this edge. This is used to identify the target node in the tree.
  final String target;

  /// The metadata of this edge. This is used to display the edge in the tree.
  final EdgeMetadata metadata;

  /// Creates a new instance of [Edge].
  const Edge({
    required this.id,
    required this.source,
    required this.target,
    required this.metadata,
  });

  /// Converts the [Edge] to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'target': target,
      'metadata': metadata.toJson(),
    };
  }

}

/// A [EdgeMetadata] is a class that represents the metadata of an edge in the inspector.
abstract class EdgeMetadata {

  /// The name of the module that this edge points from. This is used to identify the module in the tree.
  final String sourceModuleName;

  /// The name of the module that this edge points to. This is used to identify the module in the tree.
  final String targetModuleName;

  /// The type of the edge. This is used to display the edge in the tree.
  final String type;

  /// Creates a new instance of [EdgeMetadata].
  const EdgeMetadata({
    required this.sourceModuleName,
    required this.targetModuleName,
    required this.type,
  });

  /// Converts the [EdgeMetadata] to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'sourceModuleName': sourceModuleName,
      'targetModuleName': targetModuleName,
      'type': type,
    };
  }

}

/// A [ClassToClassEdgeMetadata] is a class that represents the metadata of an edge between two classes in the inspector.
class ClassToClassEdgeMetadata extends EdgeMetadata {

  /// The name of the class that this edge points from. This is used to identify the class in the tree.
  final String sourceClassName;

  /// The name of the class that this edge points to. This is used to identify the class in the tree.
  final String targetClassName;

  /// Indicates if the edge represents an internal edge.
  final bool? internal;

  /// The key of the edge. This is used to identify the edge in the tree.
  final Object? key;

  /// Creates a new instance of [ClassToClassEdgeMetadata].
  const ClassToClassEdgeMetadata({
    required super.sourceModuleName,
    required super.targetModuleName,
    required this.sourceClassName,
    required this.targetClassName,
    this.key,
    this.internal,
  }) : super(
    type: 'class_to_class',
  );

}

/// A [ModuleToModuleEdgeMetadata] is a class that represents the metadata of a module to module edge in the inspector.
class ModuleToModuleEdgeMetadata extends EdgeMetadata {

  /// Creates a new instance of [ModuleToModuleEdgeMetadata].
  const ModuleToModuleEdgeMetadata({
    required super.sourceModuleName,
    required super.targetModuleName,
  }) : super(
    type: 'module_to_module',
  );

}