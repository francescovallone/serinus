import '../../enums/enums.dart';
import '../../extensions/string_extensions.dart';
import '../../versioning.dart';
import '../core.dart';

class RoutesMapper {

  final ApplicationConfig config;

  RoutesMapper(this.config);

  RouteInfo routeToRouteInfo(Route route, Controller controller) {
    final globalPrefix = (config.globalPrefix?.prefix ?? '').addLeadingSlash();
    return RouteInfo(
      path: '${globalPrefix == '/' ? '' : globalPrefix}${controller.path.addLeadingSlash()}${route.path.addLeadingSlash()}',
      method: route.method,
      versions: [
        if(route.version != null)
          VersioningOptions(
            version: route.version!,
            type: VersioningType.uri,
          ),
        if(controller.version != null && route.version == null) 
          VersioningOptions(
            version: controller.version!,
            type: VersioningType.uri,
          ),
        if(config.versioningOptions != null && route.version == null && controller.version == null)
          config.versioningOptions!
      ]
    );
  }

  List<RouteInfo> controllerToRouteInfo(Controller controller) {
    return controller.routes.values.map((spec) {
      return routeToRouteInfo(spec.route, controller);
    }).toList();
  }

}