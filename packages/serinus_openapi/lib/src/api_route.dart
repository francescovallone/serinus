import 'package:openapi_types/commons.dart';
import 'package:openapi_types/open_api_v2.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';

/// The [ApiRoute] class is used to define an API route.
abstract class ApiRoute<Res, Params> extends Route {
  /// The [apiSpec] property contains the API specification.
  /// The [ApiRoute] constructor is used to create a new instance of the [ApiRoute] class.
  ApiRoute({
    required super.path,
    super.method = HttpMethod.get,
    this.queryParameters = const {},
    this.responses,
    this.parameters,
  });

  final Map<String, Type> queryParameters;

  final Res? responses;

  final Params? parameters;

  OpenApiVersion get openApiVersion;

  static ApiRouteV2 v2({
    required String path,
    HttpMethod method = HttpMethod.get,
    Map<String, Type> queryParameters = const {},
    Map<String, ResponseObjectV2> responses = const {},
    List<ParameterObjectV2> parameters = const [],
  }) {
    return ApiRouteV2(
      path: path,
      method: method,
      queryParameters: queryParameters,
      responses: responses,
      parameters: parameters,
    );
  }

  static ApiRouteV3 v3({
    required String path,
    HttpMethod method = HttpMethod.get,
    Map<String, Type> queryParameters = const {},
    ResponsesV3? responses,
    List<ParameterObjectV3> parameters = const [],
  }) {
    return ApiRouteV3(
      path: path,
      method: method,
      queryParameters: queryParameters,
      responses: responses,
      parameters: parameters,
    );
  }

  static ApiRouteV31 v31({
    required String path,
    HttpMethod method = HttpMethod.get,
    Map<String, Type> queryParameters = const {},
    ResponsesV31? responses,
    List<ParameterObjectV3> parameters = const [],
  }) {
    return ApiRouteV31(
      path: path,
      method: method,
      queryParameters: queryParameters,
      responses: responses,
      parameters: parameters,
    );
  }
  
}

class ApiRouteV2 extends ApiRoute<Map<String, ResponseObjectV2>, List<ParameterObjectV2>> {
  /// The [apiSpec] property contains the API specification.
  /// The [ApiRoute] constructor is used to create a new instance of the [ApiRoute] class.
  ApiRouteV2({
    required super.path,
    super.method = HttpMethod.get,
    super.queryParameters = const {},
    super.responses = const {},
    super.parameters = const [],
  });

  @override
  OpenApiVersion get openApiVersion => OpenApiVersion.v2;

}

class ApiRouteV3 extends ApiRoute<ResponsesV3, List<ParameterObjectV3>> {
  /// The [apiSpec] property contains the API specification.
  /// The [ApiRoute] constructor is used to create a new instance of the [ApiRoute] class.
  ApiRouteV3({
    required super.path,
    super.method = HttpMethod.get,
    super.queryParameters = const {},
    ResponsesV3? responses,
    super.parameters = const [],
  }) : super(responses: responses ?? ResponsesV3({}));

  @override
  OpenApiVersion get openApiVersion => OpenApiVersion.v3_0;

}

class ApiRouteV31 extends ApiRoute<ResponsesV31, List<ParameterObjectV3>> {
  /// The [apiSpec] property contains the API specification.
  /// The [ApiRoute] constructor is used to create a new instance of the [ApiRoute] class.
  ApiRouteV31({
    required super.path,
    super.method = HttpMethod.get,
    super.queryParameters = const {},
    ResponsesV31? responses,
    super.parameters = const [],
  }) : super(responses: responses ?? ResponsesV31({}));

  @override
  OpenApiVersion get openApiVersion => OpenApiVersion.v3_1;

}

