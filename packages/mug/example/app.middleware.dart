import '../lib/mug.dart';

class AppMiddleware implements MugMiddleware{
  @override
  use(Request request, Response response, void Function() next) {
    response.headers.add("testHeader", 100);
    next();
  }
}