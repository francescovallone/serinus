import '../containers/injection_token.dart';

/// A [Node] is a class that represents a node in the tree structure of the inspector.
abstract class Node {
  /// The id of this node. This is used to identify the node in the tree.
  /// This id is unique for each node in the tree. It is used to build the tree structure.
  final InjectionToken id;

  /// The label of this node. This is used to display the node in the tree.
  final String label;

  /// The parent of this node. This is used to build the tree structure.
  const Node({
    required this.id,
    required this.label,
  });

  /// Converts the [Node] to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'id': id.name,
      'label': label,
    };
  }
}

/// A [ClassNode] is a class that represents a provider in the inspector.
class ClassNode extends Node {
  /// The id of the parent node. This is used to build the tree structure.
  final InjectionToken parent;

  /// The metadata of the class. This is used to display the class in the tree.
  final ClassMetadataNode metadata;

  /// The constructor of the [ClassNode] class.
  const ClassNode({
    required super.id,
    required super.label,
    required this.parent,
    required this.metadata,
  });

  /// Converts the [ClassNode] to a JSON object.
  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'parent': parent,
      'metadata': metadata.toJson(),
    };
  }
}

/// A [ModuleNode] is a class that represents a module in the inspector.
class ModuleNode extends Node {
  /// The metadata of the module. This is used to display the module in the tree.
  final ModuleMetadataNode metadata;

  /// The constructor of the [ModuleNode] class.
  const ModuleNode({
    required super.id,
    required super.label,
    required this.metadata,
  });

  /// Converts the [ModuleNode] to a JSON object.
  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'metadata': metadata.toJson(),
    };
  }
}

/// A [ModuleMetadataNode] is a class that represents the metadata of a module in the inspector.
class ModuleMetadataNode {
  /// The name of the module. This is used to identify the module in the tree.
  final String name = 'module';

  /// Indicates if the module represents an internal module.
  final bool? internal;

  /// Indicates if the module represents a global module.
  final bool? global;

  /// Creates a new instance of [ModuleMetadataNode].
  const ModuleMetadataNode({
    this.internal,
    this.global,
  });

  /// Converts the [ModuleMetadataNode] to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (internal != null) 'internal': internal,
      if (global != null) 'global': global,
    };
  }
}

/// A [ClassMetadataNode] is a class that represents the metadata of a class in the inspector.
class ClassMetadataNode {
  /// The type of the class. This is used to identify the class in the tree.
  /// It can be one of the following:
  /// - `provider` - The class is a regular class.
  /// - `controller` - The class is a factory class.
  /// - `middleware` - The class is a service class.
  final InjectableType type;

  /// The name of the module where the class is defined.
  final InjectionToken sourceModuleName;

  /// Indicates if the provider is exported.
  final bool? exported;

  /// Indicates if the provider is composed.
  final bool? composed;

  /// The time it took to initialize the class, in milliseconds.
  final int initTime;

  /// Indicates if the class represents an internal class.
  final bool? internal;

  /// Creates a new instance of [ClassMetadataNode].
  const ClassMetadataNode({
    required this.type,
    required this.sourceModuleName,
    this.initTime = 0,
    this.composed,
    this.exported,
    this.internal,
  });

  /// Converts the [ClassMetadataNode] to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'sourceModuleName': sourceModuleName.name,
      'initTime': initTime,
      if (exported != null) 'exported': exported,
      if (composed != null) 'composed': composed,
      if (internal != null) 'internal': internal,
    };
  }
}


/// An enum that represents the type of a class in the inspector.
enum InjectableType {
  /// The class is a regular class.
  provider('provider'),

  /// The class is a factory class.
  controller('controller'),

  /// The class is a service class.
  middleware('middleware'),;
  
  const InjectableType(this.name);

  /// The name of the class type.
  final String name;

}