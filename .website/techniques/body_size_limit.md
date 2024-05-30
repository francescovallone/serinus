# Limit the size of the body of the request

When you are building a web application, you should always limit the size of the body of the request. This is important because it can help prevent denial of service attacks. If you don't limit the size of the body of the request, an attacker could send a large amount of data to your server, which could cause it to run out of memory and crash.

To limit the size of the body of the request, you can use the `BodySizeLimit` class. This class takes the maximum size of the body of the request as an argument. Here is an example of how you can use the `BodySizeLimit` class to limit the size of the body of the request to 1MB:

```dart
import 'package:serinus/serinus.dart';

void main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule());
  app.setBodySizeLimit(BodySizeLimit.change(json: 1, size: BodySizeValue.mb));
  await app.serve();
}
```

In this example, we create a new instance of the `BodySizeLimit` class with a size of 1MB and set it as the body size limit of the application. This will ensure that the size of the json body of the request is limited to 1MB. If the size of the json body of the request exceeds 1MB, the server will return a `413 Payload Too Large` response.

## Body Size Values

You can also set the body size limit to a different size by changing the value of the `size` parameter. The `size` parameter can be set to one of the following values:

- `BodySizeValue.b`: Bytes
- `BodySizeValue.kb`: Kilobytes
- `BodySizeValue.mb`: Megabytes
- `BodySizeValue.gb`: Gigabytes

## Default sizes

The default size of the BodySizeLimit for each type of allowed body is:

- `json`: 1MB
- `form`: 10MB
- `text`: 1MB
- `bytes`: 1MB
