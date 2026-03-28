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
    callback.call(
        options,
        (request.headers[options.key.toLowerCase()] == options.value)
            ? true
            : null,
        done);
  }
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
      return {'id': 'demo-user'};
    }
    return null;
  }
}

final headerFrontierStrategy = HeaderFrontierStrategy(
  HeaderStrategy(
    HeaderOptions(key: 'Authorization', value: 'hello'),
    (options, result, done) async {
      done(result);
    },
  ),
);

class AppModule extends Module {
  AppModule()
      : super(
          imports: [
            FrontierModule(),
          ],
          controllers: [AppController()],
          providers: [
            headerFrontierStrategy
          ],
        );
}
