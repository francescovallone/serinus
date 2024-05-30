import 'enums/enums.dart';

/// Options for versioning the API
/// 
/// The versioning can be done in two ways:
/// 
/// - [VersioningType.uri] - The version is added to the uri of the api
/// - [VersioningType.header] - The version is added to the headers of the api
final class VersioningOptions {
  /// The global version of the API
  final int version;

  /// The type of the versioning.
  ///
  /// If [VersioningType.uri] then the url of the api will be composed as following
  /// v${version}/${controllerPath}/${routePath}
  ///
  /// If [VersioningType.header] then the headers will be populated with
  final VersioningType type;

  /// The header name to be used when the versioning type is [VersioningType.header]
  /// 
  /// This is a required field when the versioning type is [VersioningType.header]
  final String? header;

  /// Creates a new instance of [VersioningOptions]
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
