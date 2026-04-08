import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class _RootModule extends Module {}

class _UsersModule extends Module {}

class _PostsModule extends Module {}

class _DuplicateModule extends Module {}

ApplicationConfig _config() {
  return ApplicationConfig(
    serverAdapter: SerinusHttpAdapter(
      host: 'localhost',
      port: 3000,
      poweredByHeader: 'Powered by Serinus',
    ),
  );
}

void main() {
  group('$RouterModule', () {
    test(
      'registerAsync returns DynamicModule and registers mounted module paths',
      () async {
        final module = RouterModule([
          ModuleMount(path: '/api', module: _RootModule),
          ModuleMount(path: '/v1', module: _UsersModule),
        ]);

        final registered = await module.registerAsync(_config());

        expect(registered, isA<DynamicModule>());
        expect(module.modulePaths[_RootModule], equals('/api'));
        expect(module.modulePaths[_UsersModule], equals('/v1'));
      },
    );

    test(
      'registerAsync recursively registers children using full mounted path',
      () async {
        final module = RouterModule([
          ModuleMount(
            path: '/api',
            module: _RootModule,
            children: const [
              ModuleMount(path: '/users', module: _UsersModule),
              ModuleMount(
                path: '/posts',
                module: _PostsModule,
                children: [ModuleMount(path: '/:id', module: _DuplicateModule)],
              ),
            ],
          ),
        ]);

        await module.registerAsync(_config());

        expect(module.modulePaths[_RootModule], equals('/api'));
        expect(module.modulePaths[_UsersModule], equals('/api/users'));
        expect(module.modulePaths[_PostsModule], equals('/api/posts'));
        expect(module.modulePaths[_DuplicateModule], equals('/api/posts/:id'));
      },
    );

    test(
      'throws InitializationError when the same module type is mounted twice',
      () {
        final module = RouterModule([
          ModuleMount(path: '/api', module: _RootModule),
          ModuleMount(path: '/other', module: _RootModule),
        ]);

        expect(
          () => module.registerAsync(_config()),
          throwsA(
            isA<InitializationError>().having(
              (error) => error.message,
              'message',
              contains('already registered with path /api'),
            ),
          ),
        );
      },
    );
  });
}
