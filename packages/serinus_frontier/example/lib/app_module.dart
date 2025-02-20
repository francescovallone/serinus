import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/serinus_frontier.dart';

import 'app_controller.dart';

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

class AppModule extends Module {
  AppModule()
      : super(
          imports: [FrontierModule(
            [HeaderStrategy(HeaderOptions(key: 'Authorization', value: 'hello'), (options, result, done) async {
              done(result);
            })],
          )],
          controllers: [AppController()],
        );
}
