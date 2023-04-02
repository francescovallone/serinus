// coverage:ignore-file
import 'package:serinus/serinus.dart';

class AppMiddleware implements SerinusMiddleware{
  @override
  use(Request request, Response response, void Function() next) {
    response.headers.add("testHeader", 100);
    next();
  }
}