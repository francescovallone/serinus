<script setup>
	import PluginType from '../components/plugin_type.vue'
    import PluginButtons from '../components/plugin_buttons.vue'
</script>

# Liquify

<PluginType :types="['View Engine']" />

Liquify is a comprehensive Dart implementation of the Liquid template language, originally created by Shopify. This high-performance library allows you to parse, render, and extend Liquid templates in your Dart and Flutter applications.

Serinus Liquify is a plugin that allows you to use the Liquify library in your Serinus application with ease. It provides a simple way to integrate the Liquify template engine into your Serinus application, enabling you to create dynamic and reusable templates.

## Installation

To install Serinus you can use the following command:

```bash
dart pub add serinus_liquify
```

## Usage

To use the Liquify template engine in your Serinus application, you need to add the LiquifyEngine to the application. This can be done using this code:

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_liquify/serinus_liquify.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
    entrypoint: AppModule()
  );

  // Add the Liquify engine to the application
  app.viewEngine = LiquifyEngine();

  // Start the application
  await app.serve();
}
```

Serinus also exports from the Liquify library the `TagRegistry` and the `FilterRegistry` allowing you to expand even further the capabilities of your templates with custom implementations.

You can use the `TagRegistry` to register your own custom tags and the `FilterRegistry` to register your own custom filters. This allows you to create reusable components and functions that can be used in your templates.

```dart
import 'package:serinus/serinus.dart';

import 'package:serinus_liquify/serinus_liquify.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
	entrypoint: AppModule()
  );
  TagRegistry.register('box', (content, filters) => BoxTag(content, filters));
  FilterRegistry.register('sum', (value, args, namedArgs) {
    if (value is! List) {
      return value;
    }
    return (value as List<int>).reduce((int a, int b) => a + b);
  });
  // Add the Liquify engine to the application
  app.viewEngine = LiquifyEngine(
	root: FileSystemRoot(
	  'assets/templates',
	),
  );

  // Start the application
  await app.serve();
}
```

## Options

The plugin allows you to specify the `Root` that the engine will use to find the templates.

```dart
import 'package:serinus/serinus.dart';

import 'package:serinus_liquify/serinus_liquify.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
	entrypoint: AppModule()
  );

  // Add the Liquify engine to the application
  app.viewEngine = LiquifyEngine(
	root: FileSystemRoot(
	  'assets/templates',
	),
  );

  // Start the application
  await app.serve();
}
```

::: warning
If you do not specify the `root` option, you won't be able to use the `*.liquid` templates and the engine will not be able to find the templates. You can only use the string templates.
:::

`Root` is a very special class that allows you to load templates from different locations. File System, Memory Maps or even remote servers. Internally they are in charge of loading the templates and saving their content and metadata so that they can be used later.

## Links

<PluginButtons 
  :buttons="[
    {
      label: 'Pub.dev',
      url: 'https://pub.dev/packages/serinus_liquify',
    },
	{
	  label: 'Liquify Pub.dev',
	  url: 'https://pub.dev/packages/liquify',
	},
	{
	  label: 'Liquify Github',
	  url: 'https://github.com/kingwill101/liquify'
	}
  ]" 
/>