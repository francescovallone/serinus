import 'package:mug/mug.dart';

class DataMiddleware implements MugMiddleware{
  @override
  use(Request request, Response response, void Function() next) {
    response.headers.add("testHeader2", 100);
    next();
  }
}