import 'package:serinus/serinus.dart';
import 'package:serinus/src/router/atlas.dart';
import 'package:test/test.dart';

void main() {
  group('Atlas Router', () {
    group('Basic Routing', () {
      test('should add and lookup a simple static route', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users', 'users-handler');

        final result = atlas.lookup(HttpMethod.get, '/users');

        expect(result, isA<FoundRoute<String>>());
        expect(result.values, contains('users-handler'));
        expect(result.params, isEmpty);
      });

      test('should add and lookup root path', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/', 'root-handler');

        final result = atlas.lookup(HttpMethod.get, '/');

        expect(result, isA<FoundRoute<String>>());
        expect(result.values, contains('root-handler'));
      });

      test('should add and lookup nested static routes', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/api/v1/users', 'api-users-handler');

        final result = atlas.lookup(HttpMethod.get, '/api/v1/users');

        expect(result, isA<FoundRoute<String>>());
        expect(result.values, contains('api-users-handler'));
      });

      test('should return NotFoundRoute for non-existent path', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users', 'users-handler');

        final result = atlas.lookup(HttpMethod.get, '/posts');

        expect(result, isA<NotFoundRoute<String>>());
        expect(result.values, isEmpty);
      });

      test('should handle paths with and without trailing slashes', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/', 'users-handler');

        final result = atlas.lookup(HttpMethod.get, '/users');

        expect(result, isA<FoundRoute<String>>());
        expect(result.values, contains('users-handler'));
      });

      test('should handle paths without leading slash', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, 'users', 'users-handler');

        final result = atlas.lookup(HttpMethod.get, '/users');

        expect(result, isA<FoundRoute<String>>());
        expect(result.values, contains('users-handler'));
      });
    });

    group('HTTP Methods', () {
      test('should distinguish between different HTTP methods', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users', 'get-handler');
        atlas.add(HttpMethod.post, '/users', 'post-handler');
        atlas.add(HttpMethod.delete, '/users', 'delete-handler');

        final getResult = atlas.lookup(HttpMethod.get, '/users');
        final postResult = atlas.lookup(HttpMethod.post, '/users');
        final deleteResult = atlas.lookup(HttpMethod.delete, '/users');

        expect(getResult.values, contains('get-handler'));
        expect(postResult.values, contains('post-handler'));
        expect(deleteResult.values, contains('delete-handler'));
      });

      test(
        'should return MethodNotAllowedRoute when method not registered',
        () {
          final atlas = Atlas<String>();
          atlas.add(HttpMethod.get, '/users', 'get-handler');

          final result = atlas.lookup(HttpMethod.post, '/users');

          expect(result, isA<MethodNotAllowedRoute<String>>());
        },
      );

      test('should match HttpMethod.all for any method', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.all, '/users', 'all-handler');

        final getResult = atlas.lookup(HttpMethod.get, '/users');
        final postResult = atlas.lookup(HttpMethod.post, '/users');
        final deleteResult = atlas.lookup(HttpMethod.delete, '/users');

        expect(getResult.values, contains('all-handler'));
        expect(postResult.values, contains('all-handler'));
        expect(deleteResult.values, contains('all-handler'));
      });

      test('should return both specific and all handlers when both exist', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users', 'get-handler');
        atlas.add(HttpMethod.all, '/users', 'all-handler');

        final result = atlas.lookup(HttpMethod.get, '/users');

        expect(result.values, contains('get-handler'));
        expect(result.values, contains('all-handler'));
        expect(result.values.length, 2);
      });
    });

    group('Route Parameters - Angle Bracket Syntax', () {
      test('should capture single parameter with <id> syntax', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/<id>', 'user-handler');

        final result = atlas.lookup(HttpMethod.get, '/users/123');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['id'], '123');
      });

      test('should capture multiple parameters', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/<userId>/posts/<postId>', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/users/42/posts/99');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['userId'], '42');
        expect(result.params['postId'], '99');
      });

      test('should capture parameter with prefix', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/files/user_<id>', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/files/user_123');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['id'], '123');
      });

      test('should not match parameter with wrong prefix', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/files/user_<id>', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/files/admin_123');

        expect(result, isA<NotFoundRoute<String>>());
      });

      test('should capture parameter with suffix', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/files/<name>.json', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/files/config.json');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['name'], 'config');
      });

      test('should not match parameter with wrong suffix', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/files/<name>.json', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/files/config.xml');

        expect(result, isA<NotFoundRoute<String>>());
      });

      test('should capture parameter with both prefix and suffix', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/files/doc_<name>.pdf', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/files/doc_report.pdf');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['name'], 'report');
      });
    });

    group('Route Parameters - Colon Syntax', () {
      test('should capture single parameter with :id syntax', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/:id', 'user-handler');

        final result = atlas.lookup(HttpMethod.get, '/users/456');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['id'], '456');
      });

      test('should capture multiple parameters with colon syntax', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/:userId/posts/:postId', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/users/10/posts/20');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['userId'], '10');
        expect(result.params['postId'], '20');
      });

      test('should work with mixed static and param segments', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/api/users/:id/profile', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/api/users/123/profile');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['id'], '123');
      });
    });

    group('Optional Parameters', () {
      test('should match optional parameter with and without value', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/data/<value>?', 'handler');

        final withValue = atlas.lookup(HttpMethod.get, '/data/1');
        final withoutValue = atlas.lookup(HttpMethod.get, '/data');

        expect(withValue, isA<FoundRoute<String>>());
        expect(withValue.params['value'], '1');
        expect(withoutValue, isA<FoundRoute<String>>());
        expect(withoutValue.params['value'], isNull);
      });

      test('should support optional colon syntax', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/:id?', 'handler');

        final withValue = atlas.lookup(HttpMethod.get, '/users/42');
        final withoutValue = atlas.lookup(HttpMethod.get, '/users');

        expect(withValue.params['id'], '42');
        expect(withoutValue.params['id'], isNull);
      });

      test('should throw when optional route conflicts with static route', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/data', 'base');

        expect(
          () => atlas.add(HttpMethod.get, '/data/<value>?', 'optional'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw when static route conflicts with optional route', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/data/<value>?', 'optional');

        expect(
          () => atlas.add(HttpMethod.get, '/data', 'base'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
    group('Conflicting Parameters', () {
      test('should throw when adding :id after <id> at same level', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/<id>', 'handler1');

        expect(
          () => atlas.add(HttpMethod.get, '/users/:userId', 'handler2'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw when adding <id> after :id at same level', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/:id', 'handler1');

        expect(
          () => atlas.add(HttpMethod.get, '/users/<userId>', 'handler2'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should allow same param syntax on same path', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/<id>', 'get-handler');
        atlas.add(HttpMethod.post, '/users/<id>', 'post-handler');

        final getResult = atlas.lookup(HttpMethod.get, '/users/123');
        final postResult = atlas.lookup(HttpMethod.post, '/users/123');

        expect(getResult.params['id'], '123');
        expect(postResult.params['id'], '123');
      });
    });

    group('Wildcards', () {
      test('should match single segment with wildcard *', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/files/*', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/files/image.png');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['*'], 'image.png');
      });

      test('should not match multiple segments with single wildcard', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/files/*', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/files/images/logo.png');

        expect(result, isA<NotFoundRoute<String>>());
      });

      test('should match wildcard in middle of path', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/*/profile', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/users/anything/profile');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['*'], 'anything');
      });

      test('should combine wildcard with static segments', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/api/*/data', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/api/v1/data');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['*'], 'v1');
      });
    });

    group('Tail Wildcards', () {
      test('should match all remaining segments with **', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/assets/**', 'handler');

        final result = atlas.lookup(
          HttpMethod.get,
          '/assets/images/icons/logo.png',
        );

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['**'], 'images/icons/logo.png');
      });

      test('should match single remaining segment with **', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/static/**', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/static/file.js');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['**'], 'file.js');
      });

      test('should throw when adding children to tail wildcard', () {
        final atlas = Atlas<String>();

        expect(
          () => atlas.add(HttpMethod.get, '/files/**/extra', 'handler'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should prefer static match over tail wildcard', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/files/**', 'wildcard-handler');
        atlas.add(HttpMethod.get, '/files/specific', 'specific-handler');

        final wildcardResult = atlas.lookup(
          HttpMethod.get,
          '/files/random/path',
        );
        final specificResult = atlas.lookup(HttpMethod.get, '/files/specific');

        expect(wildcardResult.values, contains('wildcard-handler'));
        expect(specificResult.values, contains('specific-handler'));
      });
    });

    group('Priority and Specificity', () {
      test('should prefer static match over parameter', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/<id>', 'param-handler');
        atlas.add(HttpMethod.get, '/users/admin', 'static-handler');

        final paramResult = atlas.lookup(HttpMethod.get, '/users/123');
        final staticResult = atlas.lookup(HttpMethod.get, '/users/admin');

        expect(paramResult.values, contains('param-handler'));
        expect(staticResult.values, contains('static-handler'));
      });

      test('should prefer parameter over wildcard', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/*', 'wildcard-handler');
        atlas.add(HttpMethod.get, '/users/<id>', 'param-handler');

        final result = atlas.lookup(HttpMethod.get, '/users/123');

        // Param should be tried before wildcard based on match order
        expect(result, isA<FoundRoute<String>>());
      });

      test('should prefer wildcard over tail wildcard', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/files/**', 'tail-handler');
        atlas.add(HttpMethod.get, '/files/*', 'wildcard-handler');

        final singleResult = atlas.lookup(HttpMethod.get, '/files/test.txt');
        final multiResult = atlas.lookup(HttpMethod.get, '/files/a/b/c');

        expect(singleResult.values, contains('wildcard-handler'));
        expect(multiResult.values, contains('tail-handler'));
      });

      test(
        'should backtrack from more specific static route to more general parametric route',
        () {
          final atlas = Atlas<String>();
          atlas.add(HttpMethod.get, '/:entity/:id', '1');
          atlas.add(HttpMethod.get, '/users/:id/profile', '2');

          // /users/1 should match /:entity/:id since /users/:id/profile requires /profile
          final result = atlas.lookup(HttpMethod.get, '/users/1');

          expect(result, isA<FoundRoute<String>>());
          expect(result.values, contains('1'));
          expect(result.params['entity'], 'users');
          expect(result.params['id'], '1');
        },
      );

      test(
        'should match exact user request: /:entity/:id vs /users/:id/profile',
        () {
          final atlas = Atlas<int>();
          atlas.add(HttpMethod.get, '/:entity/:id', 1);
          atlas.add(HttpMethod.get, '/users/:id/profile', 2);

          final result = atlas.lookup(HttpMethod.get, '/users/1');

          expect(result, isA<FoundRoute<int>>());
          expect(result.values.first, 1);
          expect(result.params['entity'], 'users');
          expect(result.params['id'], '1');
        },
      );

      test('should match more specific route when path is complete', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/:entity/:id', '1');
        atlas.add(HttpMethod.get, '/users/:id/profile', '2');

        // /users/1/profile should match /users/:id/profile
        final result = atlas.lookup(HttpMethod.get, '/users/1/profile');

        expect(result, isA<FoundRoute<String>>());
        expect(result.values, contains('2'));
        expect(result.params['id'], '1');
      });

      test('should backtrack through multiple static segments', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/:a/:b', 'generic');
        atlas.add(HttpMethod.get, '/api/:version/users', 'specific');

        // /api/v1 should match /:a/:b since /api/:version/users requires /users
        final result = atlas.lookup(HttpMethod.get, '/api/v1');

        expect(result, isA<FoundRoute<String>>());
        expect(result.values, contains('generic'));
        expect(result.params['a'], 'api');
        expect(result.params['b'], 'v1');
      });

      test('should backtrack with mixed static and parametric segments', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/:id', 'users-id');
        atlas.add(HttpMethod.get, '/users/:id/settings', 'users-settings');
        atlas.add(HttpMethod.get, '/:entity/:id', 'generic');

        final usersResult = atlas.lookup(HttpMethod.get, '/users/123');
        final settingsResult = atlas.lookup(
          HttpMethod.get,
          '/users/123/settings',
        );
        final genericResult = atlas.lookup(HttpMethod.get, '/posts/456');

        expect(usersResult.values, contains('users-id'));
        expect(settingsResult.values, contains('users-settings'));
        expect(genericResult.values, contains('generic'));
      });
    });

    group('Complex Routes', () {
      test('should handle mixed parameter types in same tree', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/<id>', 'user-handler');
        atlas.add(HttpMethod.get, '/users/<id>/posts/*', 'posts-handler');
        atlas.add(HttpMethod.get, '/users/<id>/files/**', 'files-handler');

        final userResult = atlas.lookup(HttpMethod.get, '/users/123');
        final postsResult = atlas.lookup(
          HttpMethod.get,
          '/users/123/posts/latest',
        );
        final filesResult = atlas.lookup(
          HttpMethod.get,
          '/users/123/files/docs/report.pdf',
        );

        expect(userResult.params['id'], '123');
        expect(postsResult.params['id'], '123');
        expect(postsResult.params['*'], 'latest');
        expect(filesResult.params['id'], '123');
        expect(filesResult.params['**'], 'docs/report.pdf');
      });

      test('should handle deeply nested routes', () {
        final atlas = Atlas<String>();
        atlas.add(
          HttpMethod.get,
          '/api/v1/organizations/<orgId>/teams/<teamId>/members/<memberId>',
          'handler',
        );

        final result = atlas.lookup(
          HttpMethod.get,
          '/api/v1/organizations/org1/teams/team2/members/member3',
        );

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['orgId'], 'org1');
        expect(result.params['teamId'], 'team2');
        expect(result.params['memberId'], 'member3');
      });

      test('should handle multiple routes with shared prefixes', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/api/users', 'users-handler');
        atlas.add(HttpMethod.get, '/api/users/<id>', 'user-handler');
        atlas.add(
          HttpMethod.get,
          '/api/users/<id>/posts',
          'user-posts-handler',
        );
        atlas.add(HttpMethod.get, '/api/posts', 'posts-handler');
        atlas.add(HttpMethod.get, '/api/posts/<id>', 'post-handler');

        expect(
          atlas.lookup(HttpMethod.get, '/api/users').values,
          contains('users-handler'),
        );
        expect(atlas.lookup(HttpMethod.get, '/api/users/1').params['id'], '1');
        expect(
          atlas.lookup(HttpMethod.get, '/api/users/1/posts').values,
          contains('user-posts-handler'),
        );
        expect(
          atlas.lookup(HttpMethod.get, '/api/posts').values,
          contains('posts-handler'),
        );
        expect(atlas.lookup(HttpMethod.get, '/api/posts/2').params['id'], '2');
      });
    });

    group('Edge Cases', () {
      test('should handle empty path', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '', 'root-handler');

        final result = atlas.lookup(HttpMethod.get, '/');

        expect(result, isA<FoundRoute<String>>());
      });

      test('should handle path with only slashes', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/', 'root-handler');

        final result = atlas.lookup(HttpMethod.get, '///');

        // Should normalize to root
        expect(result, isA<FoundRoute<String>>());
      });

      test('should handle parameter values with special characters', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/<id>', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/users/user-with-dashes');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['id'], 'user-with-dashes');
      });

      test('should handle parameter values with numbers', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/items/<id>', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/items/12345');

        expect(result.params['id'], '12345');
      });

      test('should handle unicode in paths', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/<name>', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/users/日本語');

        expect(result, isA<FoundRoute<String>>());
        expect(result.params['name'], '日本語');
      });

      test('should handle very long paths', () {
        final atlas = Atlas<String>();
        final longPath = '/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z';
        atlas.add(HttpMethod.get, longPath, 'handler');

        final result = atlas.lookup(HttpMethod.get, longPath);

        expect(result, isA<FoundRoute<String>>());
      });

      test('should return add success status', () {
        final atlas = Atlas<String>();

        final result = atlas.add(HttpMethod.get, '/test', 'handler');

        expect(result, isTrue);
      });
    });

    group('AtlasResult', () {
      test('params should be lazily computed and cached', () {
        final atlas = Atlas<String>();
        atlas.add(HttpMethod.get, '/users/<id>/posts/<postId>', 'handler');

        final result = atlas.lookup(HttpMethod.get, '/users/1/posts/2');

        // First access
        final params1 = result.params;
        // Second access should return cached value
        final params2 = result.params;

        expect(identical(params1, params2), isTrue);
        expect(params1['id'], '1');
        expect(params1['postId'], '2');
      });

      test('NotFoundRoute should have empty params and values', () {
        final result = NotFoundRoute<String>();

        expect(result.params, isEmpty);
        expect(result.values, isEmpty);
      });

      test('MethodNotAllowedRoute should have empty params and values', () {
        final result = MethodNotAllowedRoute<String>();

        expect(result.params, isEmpty);
        expect(result.values, isEmpty);
      });

      test('factory constructors should create correct types', () {
        final notFound = AtlasResult<String>.notFound();
        final methodNotAllowed = AtlasResult<String>.methodNotAllowed();

        expect(notFound, isA<NotFoundRoute<String>>());
        expect(methodNotAllowed, isA<MethodNotAllowedRoute<String>>());
      });
    });

    group('Generic Type Support', () {
      test('should work with function handlers', () {
        final atlas = Atlas<Function>();
        String handler(String msg) => msg;
        atlas.add(HttpMethod.get, '/test', handler);

        final result = atlas.lookup(HttpMethod.get, '/test');

        expect(result.values.first, equals(handler));
      });

      test('should work with integer handlers', () {
        final atlas = Atlas<int>();
        atlas.add(HttpMethod.get, '/route1', 1);
        atlas.add(HttpMethod.get, '/route2', 2);

        expect(atlas.lookup(HttpMethod.get, '/route1').values.first, 1);
        expect(atlas.lookup(HttpMethod.get, '/route2').values.first, 2);
      });

      test('should work with custom class handlers', () {
        final atlas = Atlas<_TestHandler>();
        final handler = _TestHandler('test');
        atlas.add(HttpMethod.get, '/test', handler);

        final result = atlas.lookup(HttpMethod.get, '/test');

        expect(result.values.first.name, 'test');
      });
    });

    group('Performance Considerations', () {
      test('should handle many routes efficiently', () {
        final atlas = Atlas<int>();

        // Add 1000 routes
        for (var i = 0; i < 1000; i++) {
          atlas.add(HttpMethod.get, '/route$i', i);
        }

        // Lookup should still be fast
        final stopwatch = Stopwatch()..start();
        for (var i = 0; i < 1000; i++) {
          atlas.lookup(HttpMethod.get, '/route$i');
        }
        stopwatch.stop();

        // Should complete in reasonable time (less than 100ms for 1000 lookups)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should handle routes with shared prefixes efficiently', () {
        final atlas = Atlas<int>();

        // Add routes with common prefixes
        for (var i = 0; i < 100; i++) {
          atlas.add(HttpMethod.get, '/api/v1/users/$i', i);
          atlas.add(HttpMethod.get, '/api/v1/posts/$i', i + 100);
          atlas.add(HttpMethod.get, '/api/v2/users/$i', i + 200);
        }
        final result = atlas.lookup(HttpMethod.get, '/api/v1/users/50');
        expect(result.values.first, 50);
      });
    });
  });
}

class _TestHandler {
  final String name;
  _TestHandler(this.name);
}
