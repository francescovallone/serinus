import 'dart:convert';
import 'dart:io';

import 'package:frontier/frontier.dart';
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
    callback.call(options, (request.headers[options.key.toLowerCase()] == options.value) ? true : null, done);
  }
}

final strategy = 
          HeaderStrategy(HeaderOptions(key: 'Authorization', value: 'Bearer token'), (options, result, done) async {
            done(result);
          },);

class AppModule extends Module {
  
  AppModule(FrontierModule module): super(controllers: [AppController()], imports: [module]);

}

class AppController extends Controller {
  
  AppController({super.path = '/'}) {
    on(Route.get('/pass', metadata: [GuardMeta('Header')]), (context) {
      return 'pass';
    });
  }

}

void main() {
  group(
    '$FrontierModule', 
    () {
      setUpAll(() async {
        final module = FrontierModule([
          strategy
        ]);
        final app = await serinus.createApplication(entrypoint: AppModule(module), loggingLevel: LogLevel.none);
        await app.serve();
      });

      test(
        '[GuardMeta] should pass the request', 
        () async {
          final req = await HttpClient().getUrl(Uri.parse('http://localhost:3000/pass'));
          req.headers.add('Authorization', 'Bearer token');
          final res = await req.close();
          final result = await res.transform(utf8.decoder).first;
          expect(result, 'pass');
        }
      );

      test(
        '[GuardMeta] should fail the request', 
        () async {
          final req = await HttpClient().getUrl(Uri.parse('http://localhost:3000/pass'));
          req.headers.add('Authorization', 'Bearer invalid');
          final res = await req.close();
          final result = await res.transform(utf8.decoder).first;
          expect(result, '{"message":"Not authorized!","statusCode":401,"uri":"No Uri"}');
          expect(res.statusCode, 401);
        }
      );
    }
  );
}
