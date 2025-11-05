import 'package:serinus/serinus.dart';
import '../serinus_openapi.dart';

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

  /// Map of query parameter names to their types.
  final Map<String, Type> queryParameters;

  /// The responses of the route.
  final Res? responses;

  /// The parameters of the route.
  final Params? parameters;

  /// The OpenAPI version of the route.
  OpenApiVersion get openApiVersion;

  /// Factory method to create an [ApiRoute] instance based on the OpenAPI version.
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

  /// Factory method to create an [ApiRoute] instance for version 3.
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

  /// Factory method to create an [ApiRoute] instance for version 3.1.
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

/// API Route implementation for OpenAPI v2.
class ApiRouteV2
    extends ApiRoute<Map<String, ResponseObjectV2>, List<ParameterObjectV2>> {
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

/// API Route implementation for OpenAPI v3.
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

/// API Route implementation for OpenAPI v3.1.
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
