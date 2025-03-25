# Limit the size of the body of the request

When you are building a web application, one of the most common case of DDoS attacks is to send a large amount of data to the server. Serinus helps you to prevent this kind of attack by limiting the size of the body of the request thanks to the `BodySizeLimitHook` hook.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule());
  app.use(BodySizeLimitHook())
  await app.serve();
}
```

By default this hook will limit the size of the body of the request to 1MB (1048576 bytes). If you want to change this value, you can pass the value in the constructor of the `BodySizeLimitHook` hook.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule());
  app.use(BodySizeLimitHook(maxSize: 1024 * 1024 * 10)) // 10MB
  await app.serve();
}
```

We have successfully configured the `BodySizeLimitHook` to limit the size of the body of the request. Now, if the size of the body of the request exceeds the limit, the server will return a `413 Payload Too Large` status code.
