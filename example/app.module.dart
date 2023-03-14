import 'package:mug/mug.dart';

import 'app.controller.dart';
import 'app.middleware.dart';
import 'data/data.module.dart';

@Module(
  imports: [DataModule()],
  controllers: [AppController]
)
class AppModule extends MugModule{
  
  @override
  configure(MiddlewareConsumer consumer) {
    consumer.apply(AppMiddleware());
    consumer.excludeRoutes([
      // ConsumerRoute(Uri.parse(''))
    ]);
  }

}