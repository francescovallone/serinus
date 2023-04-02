import 'middleware/middleware_consumer.dart';

abstract class SerinusModule{

  const SerinusModule();

  configure(MiddlewareConsumer consumer){}
}