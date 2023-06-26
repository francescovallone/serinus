import 'package:serinus/serinus.dart';

import '../app_service_copy.dart';
import 'data.controller.dart';
import 'data.middleware.dart';
import 'data.service.dart';

@Module(
  imports: const [],
  controllers: const [DataController],
  providers: const [DataService, AppServiceCopy]
)
class DataModule extends SerinusModule{

  const DataModule();

  @override
  void configure(MiddlewareConsumer consumer) {
    consumer.apply(DataMiddleware());
    consumer.excludeRoutes([
      // ConsumerRoute(Uri.parse(''))
    ]);
  }
}