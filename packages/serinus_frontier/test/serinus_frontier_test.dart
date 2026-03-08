import 'dart:convert';
import 'dart:io';

import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/serinus_frontier.dart';
import 'package:test/test.dart';

final class HeaderOptions extends StrategyOptions {
  final String key;
  final String value;

  HeaderOptions({required this.key, required this.value});
}

class HeaderResult {
  final bool authenticated;

  HeaderResult({required this.authenticated});
}

class HeaderStrategy extends Strategy<HeaderOptions> {
  HeaderStrategy(super.options, super.callback);

  String? _name;

  @override
  String get name => _name ?? 'Header';

  set name(String value) {
    _name = value;
  }

  @override
  Future<void> authenticate(StrategyRequest request) async {
    callback.call(
      options,
      (request.headers[options.key.toLowerCase()] == options.value)
          ? true
          : null,
      done,
    );
  }
}

final strategy = HeaderStrategy(
  HeaderOptions(key: 'Authorization', value: 'Bearer token'),
  (options, result, done) async {
    done(result);
  },
);

class AppModule extends Module {
  AppModule(FrontierModule module)
    : super(controllers: [AppController()], imports: [module]);
}

class AppController extends Controller {
  AppController() : super('/') {
    on(Route.get('/strategy'), (context) async {
      return context.use<Strategy>('Header').name;
    });
    on(Route.get('/pass', guards: {AuthGuard('Header')}), (context) async {
      return 'pass';
    });
  }
}

void main() {
  group('$FrontierModule', () {
    setUpAll(() async {
      final module = FrontierModule([strategy]);
      final app = await serinus.createApplication(
        entrypoint: AppModule(module),
        logLevels: {LogLevel.none},
      );
      await app.serve();
    });

    test('FrontierModule exports strategies as value providers', () async {
      final req = await HttpClient().getUrl(
        Uri.parse('http://localhost:3000/strategy'),
      );
      final res = await req.close();
      final result = await res.transform(utf8.decoder).first;
      expect(result, 'Header');
    });

    test('[AuthGuard] should pass the request', () async {
      final req = await HttpClient().getUrl(
        Uri.parse('http://localhost:3000/pass'),
      );
      req.headers.add('Authorization', 'Bearer token');
      final res = await req.close();
      final result = await res.transform(utf8.decoder).first;
      expect(result, 'pass');
    });

    test('[AuthGuard] should fail the request', () async {
      final req = await HttpClient().getUrl(
        Uri.parse('http://localhost:3000/pass'),
      );
      req.headers.add('Authorization', 'Bearer invalid');
      final res = await req.close();
      final result = await res.transform(utf8.decoder).first;
      expect(
        result,
        '{"message":"Unauthorized!","statusCode":401,"uri":"No Uri"}',
      );
      expect(res.statusCode, 401);
    });
  });
}
