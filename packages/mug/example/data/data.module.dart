import 'package:mug/mug.dart';

import 'data.controller.dart';
import 'data.middleware.dart';
import 'data.service.dart';

@Module(
  imports: const [],
  controllers: const [DataController],
  providers: const [DataService]
)
class DataModule extends MugModule{

  const DataModule();

  @override
  configure(MiddlewareConsumer consumer) {
    consumer.apply(DataMiddleware());
    consumer.excludeRoutes([
      // ConsumerRoute(Uri.parse(''))
    ]);
  }
}