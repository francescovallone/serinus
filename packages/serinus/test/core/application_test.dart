import 'dart:io';

import 'package:serinus/serinus.dart';
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

void main() {
  group('$SerinusApplication', () {
    test(
      'useAdapter should replace the primary adapter before initialization',
      () async {
        final defaultAdapter = _TrackingAdapter();
        final config = ApplicationConfig(serverAdapter: defaultAdapter);
        await defaultAdapter.init(config);
        final app = SerinusApplication(
          entrypoint: TestModule(),
          levels: {LogLevel.none},
          config: config,
        );

        final customAdapter = _TrackingAdapter(name: 'custom', port: 4000);

        await app.useAdapter(customAdapter);

        expect(app.server, same(customAdapter));
        expect(config.serverAdapter, same(customAdapter));
        expect(config.adapters.get<HttpAdapter>('http'), same(customAdapter));
        expect(defaultAdapter.closeCalls, 1);
        expect(customAdapter.initialized, true);
      },
    );

    test('useAdapter should throw after initialization', () async {
      final app = SerinusApplication(
        entrypoint: TestModule(),
        levels: {LogLevel.none},
        config: ApplicationConfig(serverAdapter: _TrackingAdapter()),
      );

      await app.initialize();

      await expectLater(
        app.useAdapter(_TrackingAdapter(name: 'custom')),
        throwsA(isA<StateError>()),
      );
    });

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

    test(
      'createMinimalApplication should use the provided adapter and support replacement',
      () async {
        final adapter = _TrackingAdapter(name: 'custom');

        final app = await serinus.createMinimalApplication(
          logLevels: {LogLevel.none},
          adapter: adapter,
        );

        expect(app.server, same(adapter));
        expect(app.config.adapters.get<HttpAdapter>('http'), same(adapter));

        final replacement = _TrackingAdapter(name: 'replacement', port: 4001);
        await app.useAdapter(replacement);

        expect(app.server, same(replacement));
        expect(app.config.serverAdapter, same(replacement));
        expect(app.config.adapters.get<HttpAdapter>('http'), same(replacement));
        expect(adapter.closeCalls, 1);
        expect(replacement.initialized, true);

        await app.close();

        expect(replacement.closeCalls, 1);
      },
    );
  });
}
