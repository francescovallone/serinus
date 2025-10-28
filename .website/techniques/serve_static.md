# Serve Static Files

Sometimes, web applications need to serve static files such as HTML, CSS, JavaScript, images, and other assets. The `serinus_serve_static` plugin provides an easy way to serve these static files in your Serinus application.

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
      ServeStaticModule({
        rootPath: '/public',
        renderPath: '*',
        serveRoot: '',
        exclude: const [], // List of paths to exclude
        extensions: const ['.html', '.css', '.js'], // List of extensions to serve
        index: const ['index.html'],
        redirect: true,
      })
    ]
  );

}
```
