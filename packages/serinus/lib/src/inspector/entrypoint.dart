class Entrypoint {

  final EntrypointType type;

  final String className;

  final String id;

  final EntrypointMetadata metadata;

  Entrypoint({
    required this.type,
    required this.className,
    required this.id,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'className': className,
      'id': id,
      'metadata': metadata.toJson(),
    };
  }

}

enum EntrypointType {
  http,
  websocket,
  middleware,
}

class EntrypointMetadata {

  final String key;

  final String path;

  final String requestMethod;

  final List<int> versions;

  EntrypointMetadata({
    required this.key,
    required this.path,
    required this.requestMethod,
    this.versions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'path': path,
      'requestMethod': requestMethod,
      'versions': versions,
    };
  }
}