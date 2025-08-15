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

}

enum EntrypointType {
  http,
  websocket,
}

class EntrypointMetadata {

  final String key;

  final String path;

  final String requestMethod;

  EntrypointMetadata({required this.key, required this.path, required this.requestMethod});
}