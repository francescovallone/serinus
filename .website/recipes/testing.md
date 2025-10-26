# Testing

Automated testing is a crucial part of software development, giving developers confidence that their code behaves as expected. Serinus provides a dedicated testing package, `serinus_test`, which simplifies the process of writing and running tests for Serinus applications.

::: warning
This package is still experimental and although it is ready to be used, some/or all of its API
might change (with deprecations) in future versions.
:::

## Application Integration Smoke Test

Application integration smoke tests focus on verifying the interactions between different modules and components within your application. With `serinus_test`, you can easily create integration tests for your Serinus applications.

Serinus simulates a real server environment leveraging the same underlying architecture as your application but removing the network overhead. This allows for fast and reliable tests.

### Create your test cases

```dart
import 'package:serinus_test/serinus_test.dart';

void main() {
  test('GET /users', () async {
    final application = await serinus.createTestApplication(
      entrypoint: AppModule(),
      host: InternetAddress.anyIPv4.address,
      port: 3002,
      logger: ConsoleLogger(
        prefix: 'Serinus Test Logger',
      ),
    );
    await application.serve();
    final res = await application.get('/users');
    res.expectStatusCode(200);
    res.expectJsonBody([
      {'id': 1, 'name': 'John Doe'},
      {'id': 2, 'name': 'Jane Smith'},
    ]);
  });
}
```

### Run your tests

```bash
dart test
```