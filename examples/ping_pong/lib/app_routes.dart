import 'package:serinus/serinus.dart';

class RootRoute extends Route {
  RootRoute() : super(path: '*', method: HttpMethod.get);
}
