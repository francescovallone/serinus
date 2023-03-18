import 'middleware/middleware_consumer.dart';

abstract class MugModule{

  const MugModule();

  configure(MiddlewareConsumer consumer){}
}