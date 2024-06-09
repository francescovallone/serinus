# CORS

Cross-Origin Resource Sharing (CORS) is a mechanism that allows many resources (e.g., fonts, JavaScript, etc.) on a web page to be requested from another domain outside the domain from which the resource originated.

Serinus provides a hook that allows you to customize the CORS behaviour of your application.

## Installation

```bash
dart pub add serinus_cors
```

## Usage

```dart
import 'package:serinus/serinus.dart';

void main(List<String> arguments) async {
  SerinusApplication application = await serinus.createApplication(
	  entrypoint: AppModule());
  application.use(CorsHook());
  await application.serve();
}
```

## Configuration

The `CorsHook` class has the following parameters:

- `allowedOrigins`: A list of origins that are allowed to access the resources of the server. If this is not set, all origins are allowed.
