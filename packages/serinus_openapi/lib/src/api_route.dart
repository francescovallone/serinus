import 'package:serinus/serinus.dart';

/// The [ApiRoute] class is used to define an API route.
class ApiRoute extends Route {
  /// The [apiSpec] property contains the API specification.
  /// The [ApiRoute] constructor is used to create a new instance of the [ApiRoute] class.
  ApiRoute({
    required super.path,
    super.method = HttpMethod.get,
    this.queryParameters = const {},
  });

  final Map<String, Type> queryParameters;
}
