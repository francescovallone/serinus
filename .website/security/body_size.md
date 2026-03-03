# Limit the size of the body of the request

When you are building a web application, one of the most common case of DDoS attacks is to send a large amount of data to the server. Serinus helps you to prevent this kind of attack by limiting the size of the body of the request thanks to the `bodySizeLimit` application option.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(),
      bodySizeLimit: 1.mb, // 1MB
  );
  await app.serve();
}
```

By default this option will limit the size of the body of the request to 10MB (10485760 bytes). If you want to change this value, you can pass the value in the `bodySizeLimit` application option.

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
    bodySizeLimit: 512.kb, // 512KB
  );
  await app.serve();
}
```

We have successfully configured the `bodySizeLimit` to limit the size of the body of the request. Now, if the size of the body of the request exceeds the limit, the server will return a `413 Payload Too Large` status code.
