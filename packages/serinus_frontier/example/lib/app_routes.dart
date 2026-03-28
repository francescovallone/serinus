import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/serinus_frontier.dart';

class HelloWorldRoute extends Route {
  HelloWorldRoute()
      : super(path: '/', method: HttpMethod.get, guards: {AuthGuard()});
}
