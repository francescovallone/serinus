import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

void main() {
  group('$Route', () {
    test(
      'when a route is created, then it should have the correct path and method',
      () {
        final route = Route(path: '/test', method: HttpMethod.get);
        expect(route.path, equals('/test'));
        expect(route.method, equals(HttpMethod.get));
      },
    );

    test(
      'when a route is created with the GET factory constructor, then it should have the correct method',
      () {
        final route = Route.get('/test');
        expect(route.method, equals(HttpMethod.get));
      },
    );

    test(
      'when a route is created with the POST factory constructor, then it should have the correct method',
      () {
        final route = Route.post('/test');
        expect(route.method, equals(HttpMethod.post));
      },
    );

    test(
      'when a route is created with the PUT factory constructor, then it should have the correct method',
      () {
        final route = Route.put('/test');
        expect(route.method, equals(HttpMethod.put));
      },
    );

    test(
      'when a route is created with the DELETE factory constructor, then it should have the correct method',
      () {
        final route = Route.delete('/test');
        expect(route.method, equals(HttpMethod.delete));
      },
    );

    test(
      'when a route is created with the PATCH factory constructor, then it should have the correct method',
      () {
        final route = Route.patch('/test');
        expect(route.method, equals(HttpMethod.patch));
      },
    );
  });
}
