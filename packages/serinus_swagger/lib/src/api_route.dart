import 'package:serinus/serinus.dart';

import 'api_spec.dart';
import 'components/components.dart';

/// The [ApiRoute] class is used to define an API route.
class ApiRoute extends Route {
  /// The [apiSpec] property contains the API specification.
  final ApiSpec apiSpec;

  /// The [ApiRoute] constructor is used to create a new instance of the [ApiRoute] class.
  const ApiRoute({
    required super.path,
    required this.apiSpec,
    super.method = HttpMethod.get,
    super.queryParameters,
  });

  /// The [get] factory constructor is used to create a new instance of the [ApiRoute] class with the GET method.
  factory ApiRoute.get({
    required String path,
    required ApiResponse response,
    RequestBody? requestBody,
    Map<String, Type> queryParameters = const {},
  }) {
    return ApiRoute(
        path: path,
        apiSpec: ApiSpec(
          responses: [response],
          requestBody: requestBody,
          parameters: queryParameters.entries
              .map((value) => ParameterObject(
                    name: value.key,
                    in_: SpecParameterType.query,
                  ))
              .toList(),
        ),
        queryParameters: queryParameters);
  }

  /// The [post] factory constructor is used to create a new instance of the [ApiRoute] class with the POST method.
  factory ApiRoute.post({
    required String path,
    required ApiResponse response,
    RequestBody? requestBody,
    Map<String, Type> queryParameters = const {},
  }) {
    return ApiRoute(
        path: path,
        apiSpec: ApiSpec(
          responses: [response],
          requestBody: requestBody,
          parameters: queryParameters.entries
              .map((value) => ParameterObject(
                    name: value.key,
                    in_: SpecParameterType.query,
                  ))
              .toList(),
        ),
        method: HttpMethod.post,
        queryParameters: queryParameters);
  }

  /// The [put] factory constructor is used to create a new instance of the [ApiRoute] class with the PUT method.
  factory ApiRoute.put({
    required String path,
    required ApiResponse response,
    RequestBody? requestBody,
    Map<String, Type> queryParameters = const {},
  }) {
    return ApiRoute(
        path: path,
        apiSpec: ApiSpec(
          responses: [response],
          requestBody: requestBody,
          parameters: queryParameters.entries
              .map((value) => ParameterObject(
                    name: value.key,
                    in_: SpecParameterType.query,
                  ))
              .toList(),
        ),
        method: HttpMethod.put,
        queryParameters: queryParameters);
  }

  /// The [delete] factory constructor is used to create a new instance of the [ApiRoute] class with the DELETE method.
  factory ApiRoute.delete({
    required String path,
    required ApiResponse response,
    RequestBody? requestBody,
    Map<String, Type> queryParameters = const {},
  }) {
    return ApiRoute(
        path: path,
        apiSpec: ApiSpec(
          responses: [response],
          requestBody: requestBody,
          parameters: queryParameters.entries
              .map((value) => ParameterObject(
                    name: value.key,
                    in_: SpecParameterType.query,
                  ))
              .toList(),
        ),
        method: HttpMethod.delete,
        queryParameters: queryParameters);
  }

  /// The [patch] factory constructor is used to create a new instance of the [ApiRoute] class with the PATCH method.
  factory ApiRoute.patch({
    required String path,
    required ApiResponse response,
    RequestBody? requestBody,
    Map<String, Type> queryParameters = const {},
  }) {
    return ApiRoute(
        path: path,
        apiSpec: ApiSpec(
          responses: [response],
          requestBody: requestBody,
          parameters: queryParameters.entries
              .map((value) => ParameterObject(
                    name: value.key,
                    in_: SpecParameterType.query,
                  ))
              .toList(),
        ),
        method: HttpMethod.patch,
        queryParameters: queryParameters);
  }
}
