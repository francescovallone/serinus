import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus/src/core/minimal/minimal_application.dart';
import 'package:test/test.dart';

class _TrackingAdapter
    extends HttpAdapter<void, InternalRequest, InternalResponse> {
  final String _adapterName;
  final bool throwOnListen;

  bool initialized = false;
  bool listened = false;
  int closeCalls = 0;

  _TrackingAdapter({
    String name = 'http',
    super.host = 'localhost',
    super.port = 3000,
    // ignore: unused_element_parameter
    this.throwOnListen = false,
  }) : _adapterName = name,
       super(poweredByHeader: 'Powered by Serinus');

  @override
  String get name => _adapterName;

  @override
  bool get isOpen => initialized && closeCalls == 0;

  @override
  Future<void> close() async {
    closeCalls++;
    initialized = false;
  }

  @override
  Future<void> init(ApplicationConfig config) async {
    initialized = true;
  }

  @override
  Future<void> listen({
    required RequestCallback<InternalRequest, InternalResponse> onRequest,
    ErrorHandler? onError,
  }) async {
    listened = true;
    if (throwOnListen) {
      throw const SocketException('listen failed');
    }
  }

  @override
  Future<void> redirect(
    InternalResponse response,
    Redirect redirect,
    ResponseContext properties,
  ) {
    return Future.value();
  }

  @override
  Future<void> reply(
    InternalResponse response,
    InternalRequest request,
    WrappedResponse body,
    ResponseContext properties,
  ) {
    return Future.value();
  }

  @override
  Future<void> render(
    InternalResponse response,
    View view,
    ResponseContext properties,
  ) {
    return Future.value();
  }
}

class TestModule extends Module {
  TestModule({super.imports = const [], super.providers = const []});
}

class TestProvider extends Provider {
  TestProvider();
}

class InvalidEntrypointModule extends Module {
  InvalidEntrypointModule()
    : super(providers: [TestProvider()], exports: [TestProvider]);
}

void main() {
  group('$SerinusApplication', () {
    test(
      'constructor adapter should replace the primary adapter before initialization',
      () async {
        final defaultAdapter = _TrackingAdapter();
        final config = ApplicationConfig(serverAdapter: defaultAdapter);
        final customAdapter = _TrackingAdapter(name: 'custom', port: 4000);
        final app = SerinusApplication(
          entrypoint: TestModule(),
          levels: {LogLevel.none},
          config: config,
          adapter: customAdapter,
        );

        expect(app.server, same(customAdapter));
        expect(config.serverAdapter, same(customAdapter));
        expect(config.adapters.get<HttpAdapter>('http'), same(customAdapter));
        expect(defaultAdapter.closeCalls, 0);
      },
    );

    test(
      'config.serverAdapter should throw after application construction',
      () {
        final app = SerinusApplication(
          entrypoint: TestModule(),
          levels: {LogLevel.none},
          config: ApplicationConfig(serverAdapter: _TrackingAdapter()),
        );

        expect(
          () => app.config.serverAdapter = _TrackingAdapter(name: 'custom'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'failed initialize should not mark the application as initialized',
      () async {
        final app = SerinusApplication(
          entrypoint: InvalidEntrypointModule(),
          levels: {LogLevel.none},
          config: ApplicationConfig(serverAdapter: _TrackingAdapter()),
        );

        await expectLater(
          app.initialize(),
          throwsA(isA<InitializationError>()),
        );

        expect(app.isInitialized, false);
      },
    );

    test('close should close the active adapter once', () async {
      final adapter = _TrackingAdapter();
      final app = SerinusApplication(
        entrypoint: TestModule(),
        levels: {LogLevel.none},
        config: ApplicationConfig(serverAdapter: adapter),
      );

      await app.serve();
      await app.close();

      expect(adapter.listened, true);
      expect(adapter.closeCalls, 1);
    });
  });

  group('$SerinusFactory', () {
    test('createApplication should use the provided adapter', () async {
      final adapter = _TrackingAdapter(name: 'custom');

      final app = await serinus.createApplication(
        entrypoint: TestModule(),
        logLevels: {LogLevel.none},
        adapter: adapter,
      );

      expect(app.server, same(adapter));
      expect(app.config.serverAdapter, same(adapter));
      expect(app.config.adapters.get<HttpAdapter>('http'), same(adapter));
      expect(adapter.initialized, true);

      await app.close();

      expect(adapter.closeCalls, 1);
    });

    test('minimal application constructor should use the provided adapter', () {
      final defaultAdapter = _TrackingAdapter();
      final customAdapter = _TrackingAdapter(name: 'custom');

      final app = SerinusMinimalApplication(
        config: ApplicationConfig(serverAdapter: defaultAdapter),
        adapter: customAdapter,
        levels: {LogLevel.none},
      );

      expect(app.server, same(customAdapter));
      expect(app.config.serverAdapter, same(customAdapter));
      expect(app.config.adapters.get<HttpAdapter>('http'), same(customAdapter));
    });

    test('createMinimalApplication should use the provided adapter', () async {
      final adapter = _TrackingAdapter(name: 'custom');

      final app = await serinus.createMinimalApplication(
        logLevels: {LogLevel.none},
        adapter: adapter,
      );

      expect(app.server, same(adapter));
      expect(app.config.adapters.get<HttpAdapter>('http'), same(adapter));

      await app.close();

      expect(adapter.closeCalls, 1);
    });
  });
}
