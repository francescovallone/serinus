# Rate Limiter

The rate limiter hook allows you to limit the number of requests that a client can make to your server in a given time frame. This can be useful for preventing abuse of your server, or for ensuring that your server remains responsive to all clients.

## Installation

To install the rate limiter hook, execute the following command:

```bash
dart pub add serinus_rate_limiter
```

## Configuration

The rate limiter hook can be configured with the following options:

- `maxRequests`: The maximum number of requests that a client can make in the given time frame. Defaults to `Infinity`.
- `duration`: The time frame in which the client can make the maximum number of requests. This can be specified in milliseconds, seconds, minutes, hours, or days. Defaults to `1 minute`.

## Example

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_rate_limiter/serinus_rate_limiter.dart';

void main() async {
  final app = await serinus.createApplication(entrypoint: AppModule());
  app.use(RateLimiterHook());
  await app.serve();
}
```
