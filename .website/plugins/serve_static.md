<script setup>
	import PluginType from '../components/plugin_type.vue'
  import PluginButtons from '../components/plugin_buttons.vue'
</script>

# Serve Static Files

<PluginType :types="['Module']" />

The `serve_static` plugin allows you to serve static files from a directory on your server. This is useful for serving images, CSS, JavaScript, and other files that do not need to be processed by Serinus.

## Installation

The installation of the plugin is immediate and can be done using the following command:

```bash
dart pub add serinus_serve_static
```

## Usage

To use the plugin, you need to import it in your entrypoint module:

```dart
import 'package:serinus_serve_static/serinus_serve_static.dart';
import 'package:serinus/serinus.dart';

class AppModule extends Module {

  AppModule() : super(imports: [ServeStaticModule()]);
  
}
```

### Options

The plugin allows you to specify the path of the directory to serve using the `path` parameter. The default value is `/public`.

```dart
import 'package:serinus_serve_static/serinus_serve_static.dart';
import 'package:serinus/serinus.dart';

class AppModule extends Module {

  AppModule() : super(
    imports: [
      ServeStaticModule(
        options: ServeStaticModuleOptions(path: '/public')
      )
    ]
  );

}
```

You can also specify the extensions that should be served using the `extensions` parameter. By default all extensions will be served.

```dart
import 'package:serinus_serve_static/serinus_serve_static.dart';
import 'package:serinus/serinus.dart';

class AppModule extends Module {

  AppModule() : super(
    imports: [
      ServeStaticModule(
        options: ServeStaticModuleOptions(
          path: '/public',
          extensions: ['.html', '.css', '.js']
        )
      )
    ]
  );

}
```

## Links

<PluginButtons 
  :buttons="[
    {
      label: 'Pub.dev',
      url: 'https://pub.dev/packages/serinus_swagger',
    },
  ]" 
/>