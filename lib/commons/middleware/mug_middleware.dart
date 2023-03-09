import 'package:mug/mug.dart';

abstract class MugMiddleware {
  use(Request request, Response response, void Function() next);
}