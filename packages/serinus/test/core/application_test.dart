import 'dart:io';
import 'dart:math';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class _MockAdapter extends Mock implements SerinusHttpAdapter {
  bool gentlyClose = false;

  @override
  String get name => 'http';

  @override
  bool get shouldBeInitilized => false;

  @override
  Future<void> listen(covariant RequestCallback requestCallback,
      {InternalRequest? request, ErrorHandler? errorHandler}) {
    throw SocketException('Failed to start server on');
  }

  @override
  Handler getHandler(
      ModulesContainer container, ApplicationConfig config, Router router) {
    return RequestHandler(router, container, config);
  }

  @override
  Future<void> close() {
    gentlyClose = true;
    return Future.value();
  }
}

class TestModule extends Module {
  TestModule({super.imports = const [], super.providers = const []});
}

void main() {
  group('$SerinusApplication', () {
    test(
        "when the adapter can't listen to requests and throw a $SocketException the application should gently shutdown",
        () async {
      final adapter = _MockAdapter();
      final app = SerinusApplication(
        entrypoint: TestModule(),
        levels: {LogLevel.none},
        config: ApplicationConfig(
            host: 'localhost',
            poweredByHeader: 'Serinus',
            port: Random().nextInt(1000) + 1000,
            serverAdapter: adapter),
      );
      await app.serve();
      expect(adapter.gentlyClose, true);
    });
  });
}
