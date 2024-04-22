# Model View Controller

Serinus can also be used with the Model View Controller (MVC) pattern. The library provides a `ViewEngine` class that can be extended to create custom view engines. The view engine is responsible for rendering the views and returning the HTML content to the client.

## Creating a View Engine

To create a view engine, you need to create a class that extends the `ViewEngine` class and override the `render` method.
In this example we will use the [MustacheX](https://pub.dev/packages/mustachex) package.

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
    final template = File('${Directory.current.path}/$viewFolder/${view.view}.mustache');
    final exists = await template.exists();
    if(exists){
      final content = await template.readAsString();
      final processed = await processor.process(content);
      return processed;
    }
    return await _notFoundView(view);
  }

  @override
  Future<String> renderString(ViewString view) async {
    final processor = MustachexProcessor(
      initialVariables: view.variables
    );
    return await processor.process(view.viewData);
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

## Using a View Engine

To use a View Engine first you need to call the `useViewEngine` method in your application.

```dart
void main(List<String> arguments) async {
  SerinusApplication application = await SerinusFactory.createApplication(
    entrypoint: AppModule()
  );
  application.useViewEngine(MustacheViewEngine());
  await application.serve();
}
```

Then you can use the `render` and the `renderString` methods in your route handlers when returning the Response.

::: code-group
```dart [Render]
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(GetRoute(path: '/'), (context, request) {
      // This refers to the view file `views/index.mustache`
      return Response.render(View(view: 'index', variables: {'name': 'Serinus'}));
    });
  }
}
```

```dart [RenderString]
import 'package:serinus/serinus.dart';

class MyController extends Controller {
  MyController({super.path = '/'}) {
    on(GetRoute(path: '/'), (context, request) {
      return Response.renderString(ViewString(viewData: 'Hello {{name}}', variables: {'name': 'Serinus'}));
    });
  }
}
```
:::