/// Represents an entry point in the application.
class Entrypoint {
  /// The type of the entry point.
  final EntrypointType type;

  /// The class name of the entry point.
  final String className;

  /// The unique identifier of the entry point.
  final String id;

  /// The metadata associated with the entry point.
  final EntrypointMetadata metadata;

  /// Creates a new instance of [Entrypoint].
  Entrypoint({
    required this.type,
    required this.className,
    required this.id,
    required this.metadata,
  });

  /// Converts the [Entrypoint] to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'className': className,
      'id': id,
      'metadata': metadata.toJson(),
    };
  }
}

/// The type of the entry point.
enum EntrypointType {
  /// HTTP entry point.
  http,

  /// WebSocket entry point.
  websocket,

  /// Middleware entry point.
  middleware,
}

/// Represents the metadata for an entry point.
class EntrypointMetadata {
  /// The unique key of the entry point.
  final String key;

  /// The path of the entry point.
  final String path;

  /// The request method of the entry point.
  final String requestMethod;

  /// The versions of the entry point.
  final List<int> versions;

  /// Creates a new instance of [EntrypointMetadata].
  EntrypointMetadata({
    required this.key,
    required this.path,
    required this.requestMethod,
    this.versions = const [],
  });

  /// Converts the [EntrypointMetadata] to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'path': path,
      'requestMethod': requestMethod,
      'versions': versions,
    };
  }
}
