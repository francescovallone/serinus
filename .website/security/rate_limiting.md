# Rate Limiting

A common technique to prevent abuse of your API is to limit the number of requests a client can make in a given amount of time. This technique is called rate limiting.

Serinus provides a way to limit the number of requests a client can make in a given amount of time using the `RateLimitHook` hook.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(entrypoint: AppModule());
  app.use(RateLimitHook(maxRequests: 100, duration: Duration(minutes: 1)));
  await app.serve();
}
```

In the example above, we have configured the `RateLimitHook` to limit the number of requests to 100 per minute. If the client exceeds this limit, the server will return a `429 Too Many Requests` status code.
