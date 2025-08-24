import 'package:serinus/serinus.dart';

class TestProvider extends Provider {
  TestProvider();

  String testMethod() {
    return 'Hello world';
  }
}

class TestProviderTwo extends Provider {
  TestProviderTwo();

  String testMethod() {
    return 'Hello world';
  }
}

class TestProviderThree extends Provider {
  TestProviderThree();

  String testMethod() {
    return 'Hello world';
  }
}

class TestMiddleware extends Middleware {
  TestMiddleware();

  @override
  Future<void> use(RequestContext context, NextFunction next) async {
    return next();
  }
}
