import 'package:serinus/serinus.dart';

abstract class SerinusMiddleware {
  use(Request request, Response response, void Function() next);
}