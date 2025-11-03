<script setup>
	import PluginType from '../components/plugin_type.vue'
    import PluginButtons from '../components/plugin_buttons.vue'
</script>

# Frontier

<PluginType :types="['Module', 'Hook']" />

Frontier is a simple strategy-based authentication library for Dart & Flutter. Extremely easy to use and highly customizable to fit your needs. It is designed to be simple and easy to use, yet powerful and flexible.

Serinus Frontier is a plugin that allows you to use the Frontier library in your Serinus application.

## Installation

The installation of the plugin is immediate and can be done using the following command:

```bash
dart pub add serinus_frontier
```

## Usage

To use the plugin, you need to import it in your entrypoint module:

```dart
import 'package:serinus_frontier/serinus_frontier.dart';

class AppModule extends Module {

  AppModule() : super(
    imports: [
        FrontierModule([
            MyStrategy(
                MyStrategyOptions(), 
                (options, value, done) => done(value)
            )
        ])
    ]);

}
```

`MyStrategy` in the example above is a Frontier strategy. You can either use the built-in strategies or create your own. The `MyStrategyOptions` is the options for the strategy. The last parameter is the strategy callback function.

The list of built-in strategies can be found [here](https://frontier.avesbox.com/strategies.html).

### Built-in Metadata

serinus_frontier provides built-in metadata that can be used to protect your routes. The metadata can be used in the `on` method of the controller or overriding the `metadata` getter in the controller.

```dart
import 'package:serinus_frontier/serinus_frontier.dart';

class MyController extends Controller {

  MyController({super.path = '/'}) {
    on(
        Route.get(
            '/', 
            metadata: [
                // MyStrategy is the name of the strategy
                GuardMeta('MyStrategy')
            ]
        ), 
        (context) => 'Hello World!'
    );
  }

}
```

## Links

<PluginButtons 
  :buttons="[
    {
      label: 'Pub.dev',
      url: 'https://pub.dev/packages/serinus_openapi',
    },
    {
      label: 'Frontier',
      url: 'frontier.avesbox.com',
    },
  ]" 
/>
