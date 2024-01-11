import 'package:serinus/serinus.dart';

import '../app.module.dart';
import '../app_service_copy.dart';
import 'data.controller.dart';
import 'data.middleware.dart';
import 'data.service.dart';

@Module(
  imports: [AppModule],
  controllers: [DataController],
  providers: [DataService, AppServiceCopy]
)
class DataModule{

  const DataModule();

  void configure(MiddlewareConsumer consumer) {
    consumer.apply(DataMiddleware());
    consumer.excludeRoutes([
      // ConsumerRoute(Uri.parse(''))
    ]);
  }
}