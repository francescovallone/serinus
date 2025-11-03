# Model View Controller

In some cases can be useful to leverage the power of server-side rendered applications, to reduce the load on the client-side, or to improve the SEO of your application. Serinus provides a way to render views using the `ViewEngine`.

To create a view engine, you first need to create a class that extends the `ViewEngine` class and implement the `render` and `renderString` methods and also a template engine to render the views.

In this guide we will use the [MustacheX](https://pub.dev/packages/mustachex) package to render the views.

```dart
import 'package:serinus/serinus.dart';
import 'package:mustachex/mustachex.dart';

class MustacheViewEngine extends ViewEngine{
  
  const MustacheViewEngine({
    super.viewFolder
  });

  @override
  Future<String> render(View view) async {
    final processor = MustachexProcessor(
      initialVariables: view.variables
    );
    String content = view.template;
    if(view.fromFile) {
      final template = File('${Directory.current.path}/$viewFolder/${view.template}.mustache');
      final exists = await template.exists();
      if(!exists){
        return await _notFoundView(view);
      }
      content = await template.readAsString();
    }
    return await processor.process(content);
;
  }

  Future<String> _notFoundView(String view) async {
    final processor = MustachexProcessor(
      initialVariables: {'view': view}
    );
    return await processor.process('View {{view}} not found');
  }
  
}
```

In the `MustacheViewEngine` class, you can pass the following parameters to the constructor:

- `viewFolder`: The folder where the views are stored. By default it is the `views` folder.

We can now use the `MustacheViewEngine` in our application.

```dart
import 'package:serinus/serinus.dart';

Future<void> main() async {
  final app = await serinus.createApplication(
      entrypoint: AppModule(), host: InternetAddress.anyIPv4, port: 3000);
  app.viewEngine = MustacheViewEngine();
  await app.serve();
}
```

## Templates

Now let's create the view that will be rendered. Create a folder called `views` in the root of your project and create a file called `home.mustache` inside the `views` folder.

```html
<!-- views/home.mustache -->
<!DOCTYPE html>
<html>
<head>
  <title>Home</title>
</head>
<body>
  <h1>Welcome to Serinus {{name}}</h1>
</body>
</html>
```

Now we can add the Route to render the view.

```dart
import 'package:serinus/serinus.dart';

class HomeController extends Controller {
  HomeController(): super('/') {
    on(Route.get('/'), (RequestContext context) async {
      return View('home', variables: {'name': 'Dear User'});
    });
  }
}
```

We can also render directly a string.

```dart
import 'package:serinus/serinus.dart';

class HomeController extends Controller {
  HomeController(): super('/') {
    on(Route.get('/'), (RequestContext context) async {
      return ViewString('Hello {{name}}', variables: {'name': 'Dear User'});
    });
  }
}
```

Now if you access the route `/` you will see the view rendered.
