class VersioningOptions {
  /// The global version of the API
  final int version;

  /// The type of the versioning.
  ///
  /// If [VersioningType.uri] then the url of the api will be composed as following
  /// v${version}/${controllerPath}/${routePath}
  ///
  /// If [VersioningType.header] then the headers will be populated with
  final VersioningType type;
  final String? header;

  VersioningOptions({required this.type, this.version = 1, this.header}) {
    if (version < 1) {
      throw ArgumentError.value(
          version, 'version', 'Version must be greater than 0');
    }
    if (type == VersioningType.header && header == null) {
      throw ArgumentError.notNull('header');
    }
  }
}

enum VersioningType {
  header,
  uri,
}
