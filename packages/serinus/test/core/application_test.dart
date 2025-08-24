import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class _MockAdapter extends Mock implements SerinusHttpAdapter {
  bool gentlyClose = false;

  @override
  // TODO: implement host
  String get host => 'localhost';

  @override
  // TODO: implement port
  int get port => 3000;

  @override
  String get name => 'http';

  @override
  Future<void> listen({
    required RequestCallback<InternalRequest, InternalResponse> onRequest,
    ErrorHandler? onError,
  }) async {
    return;
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
          config: ApplicationConfig(serverAdapter: adapter),
        );
        await app.serve();
        await app.close();
        expect(adapter.gentlyClose, true);
      },
    );
  });
}
