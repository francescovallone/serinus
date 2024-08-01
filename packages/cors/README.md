
[![Serinus Logo][logo_white]][repo_link]

# Serinus Cors

A hook for Serinus applications 🐤 to customize Cross-Origin Resource Sharing behaviour.

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

[logo_white]: https://raw.githubusercontent.com/francescovallone/serinus/main/packages/serinus/assets/serinus-logo-long.png
[repo_link]: https://github.com/francescovallone/serinus
