// coverage:ignore-file
import 'package:serinus/serinus.dart';

import '../data/data.module.dart';
import 'app.controller.dart';
import 'app.middleware.dart';

@Module(
  imports: [DataModule()],
  controllers: [AppController]
)
class AppMiddlewareModule extends SerinusModule{
  
  @override
  void configure(MiddlewareConsumer consumer) {
    consumer.apply(AppMiddleware());
    consumer.excludeRoutes([
      ConsumerRoute(Uri.parse('/test')),
      ConsumerRoute(Uri.parse('/'), 'POST')
    ]);
  }

}