import 'package:serinus/serinus.dart';
import 'package:serinus_rate_limiter/serinus_rate_limiter.dart';

import 'app_module.dart';

Future<void> bootstrap() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(), host: '0.0.0.0', port: 3000);
  app.use(RateLimiterHook(maxRequests: 10, duration: Duration(seconds: 10)));
  await app.serve();
}
