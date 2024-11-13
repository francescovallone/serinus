# Limit the size of the body of the request

When you are building a web application, you should always limit the size of the body of the request. This is important because it can help prevent denial of service attacks. If you don't limit the size of the body of the request, an attacker could send a large amount of data to your server, which could cause it to run out of memory and crash.

To limit the size of the body of the request, you can use the `BodySizeLimitHook` hook. This hook takes the maximum size of the body of the request as an argument. Here is an example of how you can use the `BodySizeLimitHook` class to limit the size of the body of the request to 1MB (1024 * 1024 bytes) in a Serinus application:

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule());
  app.use(BodySizeLimitHook())
  await app.serve();
}
```

If the size of the body of the request exceeds 1MB, the server will return a `413 Payload Too Large` response.

## Parameters

The `BodySizeLimitHook` class takes the following parameters:

- `maxSize`: The maximum size of the body of the request in bytes. The default value is `1048576` (1MB).
