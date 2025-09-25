---
title: Serinus - The modular Backend for your Flutter apps
titleTemplate: false
layout: page
sidebar: false

head:
  - - meta
    - property: 'og:title'
      content: Serinus - The modular Backend for your Flutter apps
  - - meta
    - name: 'description'
      content: Serinus is an open-source framework for building efficient and scalable backend applications powered by Dart.
  - - meta
    - property: 'og:description'
      content: Serinus is an open-source framework for building efficient and scalable backend applications powered by Dart.
  - - meta
    - property: 'og:image'
      content: https://serinus.app/serinus.webp
  - - meta
    - property: 'twitter:image'
      content: https://serinus.app/serinus.webp
---

<script setup>
  import Home from './components/home.vue';
</script>

<Home>
  <template #start>

:::code-group

```dart [Entrypoint]
import 'package:serinus/serinus.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule(),
  );
  await app.serve();
}
```

```dart [Module]
import 'package:serinus/serinus.dart';

import 'app_controller.dart';

class AppModule extends Module {
  AppModule() : super(
    controllers: [AppController()],
  );
}
```

```dart [Controller]
import 'package:serinus/serinus.dart';

class AppController extends Controller {

  AppController() : super('/') {
    on(Route.get('/'), _handleHelloWorld);
  }

  String _handleHelloWorld(RequestContext context) {
    return 'Hello, World!';
  }
}
```

:::

  </template>
  <template #configuration>

```dart
import 'package:serinus_config/serinus_config.dart';

final config = Config();
```

  </template>
</Home>
