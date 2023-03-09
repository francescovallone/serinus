import 'middleware/middleware_consumer.dart';

abstract class MugModule{
  configure(MiddlewareConsumer consumer);
}