import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:serinus/serinus.dart';
import 'package:test/test.dart';

class HookTest extends Hook
    with OnRequestResponse, OnBeforeHandle, OnAfterHandle, OnException {
  final Map<String, dynamic> data = {};

  @override
  Future<void> onRequest(Request request, InternalResponse response) async {
    data['onRequest'] = true;
  }

  @override
  Future<void> beforeHandle(RequestContext context) async {
    data['beforeHandle'] = true;
  }

  @override
  Future<void> afterHandle(RequestContext context, dynamic response) async {
    data['afterHandle'] = true;
  }

  @override
  Future<void> onResponse(
      Request request, dynamic data, ResponseProperties properties) async {
    this.data['onResponse'] = true;
  }

  @override
  Future<void> onException(RequestContext request, Exception exception) async {
    data['onException'] = true;
  }
}

class NoOverrideHook extends Hook with OnRequestResponse {}

class MockRequest extends Mock implements Request {
  final Map<String, dynamic> _data = {};

  @override
  dynamic operator [](String key) => _data[key];

  @override
  void operator []=(String key, dynamic value) => _data[key] = value;
}

class MockResponse extends Mock implements InternalResponse {}

class MockStreamableResponse extends Mock implements StreamableResponse {}

class HookRoute extends Route with OnBeforeHandle, OnAfterHandle {
  final Map<String, dynamic> data = {};

  HookRoute({super.path = '/', super.method = HttpMethod.get});

  @override
  Future<void> beforeHandle(RequestContext context) async {
    data['beforeHandle-route'] = true;
  }

  @override
  Future<void> afterHandle(RequestContext context, dynamic response) async {
    data['afterHandle-route'] = true;
  }
}

class TestController extends Controller {
  TestController(Route route, [super.path = '/']) {
    on(route, (context) async => 'ok!');
    on(Route.get('/error'), (context) async {
      throw NotFoundException('Not found');
    });
  }
}

class TestModule extends Module {
  TestModule({super.controllers});
}

void main() {
  group('$Hook', () {
    test(
        'if a hook is augmented and the methods are called then the data should be populated',
        () async {
      final hook = HookTest();
      final context =
          RequestContext({}, {}, MockRequest(), MockStreamableResponse());
      await hook.onRequest(context.request, MockResponse());
      expect(hook.data['onRequest'], true);
      await hook.beforeHandle(context);
      expect(hook.data['beforeHandle'], true);
      await hook.afterHandle(context, 'response');
      expect(hook.data['afterHandle'], true);
      await hook.onResponse(context.request, 'data', ResponseProperties());
      expect(hook.data['onResponse'], true);
    });
  });

  group('$Hookable', () {
    test(
        'if a hook or a route are augmented and the methods are called then the data should be populated',
        () async {
      final route = HookRoute();
      final app = await serinus.createApplication(
          entrypoint: TestModule(controllers: [TestController(route)]),
          port: 9000,
          logLevels: {LogLevel.none});
      final hook = HookTest();
      app.use(hook);
      app.use(NoOverrideHook());
      await app.serve();
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:9000'));
      final response = await request.close();
      expect(response.statusCode, 200);
      await app.close();
      expect(route.data['beforeHandle-route'], true);
      expect(route.data['afterHandle-route'], true);
      expect(hook.data['onRequest'], true);
      expect(hook.data['beforeHandle'], true);
      expect(hook.data['afterHandle'], true);
      expect(hook.data['onResponse'], true);
    });

    test(
        'if a hook is augmented with onException and an exception is thrown then the onException method should be called',
        () async {
      final route = HookRoute();
      final app = await serinus.createApplication(
          entrypoint: TestModule(controllers: [TestController(route)]),
          port: 9101,
          logLevels: {LogLevel.none});
      final hook = HookTest();
      app.use(hook);
      app.use(NoOverrideHook());
      await app.serve();
      final request =
          await HttpClient().getUrl(Uri.parse('http://localhost:9101/error'));
      final response = await request.close();
      expect(response.statusCode, 404);
      await app.close();
      expect(hook.data['onException'], true);
      expect(hook.data['onResponse'], true);
    });
  });
}
