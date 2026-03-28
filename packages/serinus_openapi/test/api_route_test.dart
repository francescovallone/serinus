import 'package:serinus/serinus.dart';
import 'package:serinus_openapi/serinus_openapi.dart';
import 'package:test/test.dart';

void main() {
  group('ApiRoute factories', () {
    test('creates v2 route with expected metadata', () {
      final route = ApiRoute.v2(
        path: '/users',
        method: HttpMethod.post,
        queryParameters: const {'page': int},
        responses: {
          '200': ResponseObjectV2(description: 'ok', headers: {}),
        },
        parameters: [
          ParameterObjectV2(name: 'id', in_: 'path', required: true),
        ],
      );

      expect(route, isA<ApiRouteV2>());
      expect(route.openApiVersion, OpenApiVersion.v2);
      expect(route.path, '/users');
      expect(route.method, HttpMethod.post);
      expect(route.queryParameters['page'], int);
      expect(route.responses?['200']?.description, 'ok');
      expect(route.parameters?.first.name, 'id');
    });

    test('creates v3 route with default empty responses', () {
      final route = ApiRoute.v3(path: '/items');

      expect(route, isA<ApiRouteV3>());
      expect(route.openApiVersion, OpenApiVersion.v3_0);
      expect(route.responses, isA<ResponsesV3>());
      expect(route.responses?.responses, isEmpty);
    });

    test('creates v31 route with default empty responses', () {
      final route = ApiRoute.v31(path: '/items');

      expect(route, isA<ApiRouteV31>());
      expect(route.openApiVersion, OpenApiVersion.v3_1);
      expect(route.responses, isA<ResponsesV31>());
      expect(route.responses?.responses, isEmpty);
    });
  });
}
