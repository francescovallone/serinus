import '../../../serinus.dart';
import '../../extensions/string_extensions.dart';
import '../core.dart';
import 'middleware.dart';

class RouteInfoPathExtractor {

  final ApplicationConfig config;

  String get prefixPath => (config.globalPrefix?.prefix ?? '').addLeadingSlash().stripEndSlash();

  const RouteInfoPathExtractor(this.config);

  List<String> extractPathFrom(RouteInfo route) {
    if (isWildcard(route.path) && (route.versions == null || route.versions!.isEmpty)) {
      return [route.path.addLeadingSlash()];
    }

    return extractNonWildcardPathsFrom(route);
  }

  List<String> extractNonWildcardPathsFrom(RouteInfo route) {
    final versionPaths = extractVersionPathFrom(route.versions);
    if (versionPaths.isEmpty) {
      return [prefixPath + route.path.addLeadingSlash()];
    }
    return versionPaths.map(
      (versionPath) => prefixPath + versionPath + route.path.addLeadingSlash(),
    ).toList();
  }

  List<String> extractVersionPathFrom(List<VersioningOptions>? versions) {
    if (versions == null || versions.isEmpty || versions.any((v) => v.type != VersioningType.uri)) {
      return [];
    }

    return versions.map((version) {
      final versionPrefix = version.versionPrefix;
      return '$versionPrefix${version.version}'.addLeadingSlash();
    }).toList();
  }

  bool isWildcard(String path) {
    const isSimpleWildcard = ['*', '/*', '/*/', '(.*)', '/(.*)'];
    if (isSimpleWildcard.contains(path)) {
      return true;
    }

    final wildcardRegexp = RegExp(r'^\/\{.*\}.*|^\/\*.*$');
    return wildcardRegexp.hasMatch(path);
  }

}