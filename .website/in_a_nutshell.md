# In a Nutshell

Serinus is a minimalistic framework for building efficient and scalable server-side applications powered by Dart.

Designed to be easy to use, flexible and extensible to cover all the needs of a modern server-side application.

In a nutshell, Serinus is a framework that gets out of your way and lets you focus on building your application.

Here is the simplest example of a Serinus application:

::: code-group

```dart[main.dart]
import 'package:serinus/serinus.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule());
  await app.serve();
}
```

```dart[app_module.dart]
import 'package:serinus/serinus.dart';

class AppModule extends Module {
  AppModule(): super(
	controllers: [AppController()],
  );
}
```

```dart[app_controller.dart]
import 'package:serinus/serinus.dart';

class AppController extends Controller {
  AppController(): super(path: '/') {
	on(Route.get('/'), (RequestContext context) async => 'Hello, World!');
  }
}
```

:::

## Our Community

Serinus is a community-driven project so, if you have any questions, need help, or want to contribute to the project, feel free to join our community on Discord.

<script setup>
  import BtnLink from './components/btn-link.vue';
</script>

<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
	<BtnLink link="https://discord.gg/zydgnJ3ksJ" title="Discord" description="Official Serinus discord server" />
	<BtnLink link="https://x.com/serinus_nest" title="Twitter/X" description="Keep in touch with the latest updates" />
	<BtnLink link="https://github.com/serinus-nest" title="GitHub" description="Source code and contributions" />
</div>
