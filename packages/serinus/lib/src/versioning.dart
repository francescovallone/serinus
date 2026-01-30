import 'core/core.dart';
import 'enums/enums.dart';

/// Metadata to ignore versioning for a controller or a route
class IgnoreVersion extends Metadata {
  /// Creates a new instance of [IgnoreVersion]
  const IgnoreVersion() : super(name: 'ignore_version', value: true);
}

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

  /// The prefix to be used when the versioning type is [VersioningType.uri]
  /// Defaults to 'v'
  final String prefix;

  /// Creates a new instance of [VersioningOptions]
  VersioningOptions({
    required this.type,
    this.version = 1,
    this.header,
    this.prefix = 'v',
  }) {
    if (version < 1) {
      throw ArgumentError.value(
        version,
        'version',
        'Version must be greater than 0',
      );
    }
    if (type == VersioningType.header && header == null) {
      throw ArgumentError.notNull('header');
    }
  }

  /// Returns the version prefix for the API.
  String get versionPrefix {
    return prefix;
  }

  /// Creates a new instance of [VersioningOptions] with [VersioningType.uri].
  factory VersioningOptions.uri({int version = 1}) {
    return VersioningOptions(type: VersioningType.uri, version: version);
  }

  /// Creates a new instance of [VersioningOptions] with [VersioningType.header].
  factory VersioningOptions.header({required String header, int version = 1}) {
    return VersioningOptions(
      type: VersioningType.header,
      version: version,
      header: header,
    );
  }

  @override
  bool operator ==(covariant VersioningOptions other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final otherOptions = other;
    return otherOptions.version == version &&
        otherOptions.type == type &&
        otherOptions.header == header &&
        otherOptions.prefix == prefix;
  }

  @override
  int get hashCode {
    return Object.hash(version, type, header, prefix);
  }
}
