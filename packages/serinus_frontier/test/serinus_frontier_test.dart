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

class HeaderFrontierStrategy
    extends FrontierStrategy<Map<String, String>, bool?> {
  HeaderFrontierStrategy(this.headerStrategy);

  final HeaderStrategy headerStrategy;

  @override
  String get name => headerStrategy.name;

  @override
  Strategy get strategy => headerStrategy;

  @override
  Future<Map<String, String>?> validate(
    RequestContext context,
    bool? payload,
  ) async {
    if (payload == true) {
      return {'id': 'user-1'};
    }
    return null;
  }
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

final frontierStrategy = HeaderFrontierStrategy(strategy);

class AppModule extends Module {
  AppModule()
    : super(
        controllers: [AppController()],
        imports: [FrontierModule(defaultStrategy: 'Header')],
        providers: [
          Provider.forValue<FrontierStrategy>(frontierStrategy, name: 'Header'),
        ],
      );
}

class AppController extends Controller {
  AppController() : super('/') {
    on(Route.get('/strategy'), (context) async {
      return context.use<FrontierConfig>().defaultStrategy;
    });
    on(Route.get('/pass', guards: {AuthGuard('Header')}), (context) async {
      return 'pass';
    });
    on(Route.get('/default-pass', guards: {AuthGuard()}), (context) async {
      final user = context.user<Map<String, String>>();
      return user['id'];
    });
  }
}

void main() {
  group('$FrontierModule', () {
    setUpAll(() async {
      final app = await serinus.createApplication(
        entrypoint: AppModule(),
        logLevels: {LogLevel.none},
      );
      await app.serve();
    });

    test('FrontierModule exports default strategy config', () async {
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

    test('[AuthGuard] should use the default strategy when omitted', () async {
      final req = await HttpClient().getUrl(
        Uri.parse('http://localhost:3000/default-pass'),
      );
      req.headers.add('Authorization', 'Bearer token');
      final res = await req.close();
      final result = await res.transform(utf8.decoder).first;
      expect(result, 'user-1');
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
