import '../../enums/enums.dart';
import '../../extensions/string_extensions.dart';
import '../../versioning.dart';
import '../core.dart';

/// Maps routes to their corresponding route information.
class RoutesMapper {
  /// The application configuration.
  final ApplicationConfig config;

  /// Creates a new instance of [RoutesMapper].
  RoutesMapper(this.config);

  /// Maps a [Route] and [Controller] to a [RouteInfo] object.
  RouteInfo routeToRouteInfo(Route route, Controller controller) {
    final globalPrefix = (config.globalPrefix?.prefix ?? '').addLeadingSlash();
    return RouteInfo(
      '${globalPrefix == '/' ? '' : globalPrefix}${controller.path.addLeadingSlash()}${route.path.addLeadingSlash()}',
      method: route.method,
      versions: [
        if (route.version != null)
          VersioningOptions(version: route.version!, type: VersioningType.uri),
        if (controller.version != null && route.version == null)
          VersioningOptions(
            version: controller.version!,
            type: VersioningType.uri,
          ),
        if (config.versioningOptions != null &&
            route.version == null &&
            controller.version == null)
          config.versioningOptions!,
      ],
    );
  }

  /// Maps a [Controller] to a list of [RouteInfo] objects.
  List<RouteInfo> controllerToRouteInfo(Controller controller) {
    return controller.routes.values.map((spec) {
      return routeToRouteInfo(spec.route, controller);
    }).toList();
  }
}
