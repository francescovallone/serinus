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

  /// Optional cache metadata for the entry point.
  final CacheMetadata? cache;

  /// Creates a new instance of [EntrypointMetadata].
  EntrypointMetadata({
    required this.key,
    required this.path,
    required this.requestMethod,
    this.versions = const [],
    this.cache,
  });

  /// Converts the [EntrypointMetadata] to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'path': path,
      'requestMethod': requestMethod,
      'versions': versions,
      if (cache != null) 'cache': cache!.toJson(),
    };
  }
}

/// Cache specific metadata exposed through the inspector.
class CacheMetadata {
  final bool enabled;
  final int hits;
  final int misses;
  final int stores;
  final int evictions;
  final int entries;
  final int capacity;
  final int ttlMs;
  final bool perUser;

  const CacheMetadata({
    required this.enabled,
    required this.hits,
    required this.misses,
    required this.stores,
    required this.evictions,
    required this.entries,
    required this.capacity,
    required this.ttlMs,
    required this.perUser,
  });

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'hits': hits,
      'misses': misses,
      'stores': stores,
      'evictions': evictions,
      'entries': entries,
      'capacity': capacity,
      'ttlMs': ttlMs,
      'perUser': perUser,
    };
  }
}
