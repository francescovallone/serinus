import '../../enums/enums.dart';
import '../../extensions/string_extensions.dart';
import '../../versioning.dart';
import '../core.dart';

/// Extracts the path information from a [RouteInfo] object.
class RouteInfoPathExtractor {
  /// The application configuration.
  final ApplicationConfig config;

  /// The prefix path for the route.
  String get prefixPath =>
      (config.globalPrefix?.prefix ?? '').addLeadingSlash().stripEndSlash();

  /// Creates a new instance of [RouteInfoPathExtractor].
  const RouteInfoPathExtractor(this.config);

  /// Extracts the path from the given [route].
  List<String> extractPathFrom(RouteInfo route) {
    if (isWildcard(route.path) &&
        (route.versions == null || route.versions!.isEmpty)) {
      return [route.path.addLeadingSlash()];
    }
    return extractNonWildcardPathsFrom(route);
  }

  /// Extracts the non-wildcard paths from the given [route].
  List<String> extractNonWildcardPathsFrom(RouteInfo route) {
    final versionPaths = extractVersionPathFrom(route.versions);
    if (versionPaths.isEmpty) {
      return [prefixPath + route.path.addLeadingSlash()];
    }
    return versionPaths
        .map(
          (versionPath) =>
              prefixPath + versionPath + route.path.addLeadingSlash(),
        )
        .toList();
  }

  /// Extracts the version path from the given [versions].
  List<String> extractVersionPathFrom(List<VersioningOptions>? versions) {
    if (versions == null ||
        versions.isEmpty ||
        versions.any((v) => v.type != VersioningType.uri)) {
      return [];
    }

    return versions.map((version) {
      final versionPrefix = version.versionPrefix;
      return '$versionPrefix${version.version}'.addLeadingSlash();
    }).toList();
  }

  /// Checks if the given [path] is a wildcard path.
  bool isWildcard(String path) {
    const isSimpleWildcard = ['*', '/*', '/*/', '(.*)', '/(.*)'];
    if (isSimpleWildcard.contains(path)) {
      return true;
    }

    final wildcardRegexp = RegExp(r'^\/\{.*\}.*|^\/\*.*$');
    return wildcardRegexp.hasMatch(path);
  }
}
