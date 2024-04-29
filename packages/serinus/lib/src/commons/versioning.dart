class VersioningOptions {
  /// The global version of the API
  final int? version;

  /// The type of the versioning.
  ///
  /// If [VersioningType.uri] then the url of the api will be composed as following
  /// v${version}/${controllerPath}/${routePath}
  ///
  /// If [VersioningType.header] then the headers will be populated with
  final VersioningType type;
  final String? header;

  VersioningOptions({required this.type, this.version, this.header})
      : assert(type == VersioningType.header && header != null,
            'The header field must be populated if the type is ${VersioningType.header}');
}

enum VersioningType {
  header,
  uri,
}
