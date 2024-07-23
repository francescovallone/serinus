import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:jaspr/server.dart';
import 'package:serinus/serinus.dart';
// import 'package:shelf/shelf.dart' as shelf;

import 'app_routes.dart';
import 'components/home.dart';

class AppController extends Controller {

  late Handler handler;

  AppController({super.path = '/'}) {
    on(RootRoute(), _handleHelloWorld);
    on(Route.get('/'), _handleHelloWorld);
  }

  Future<dynamic> _handleHelloWorld(RequestContext context) async {
    if(!context.request.path.contains('.')) {
      context.res.contentType = ContentType.html;
      return renderComponent(
        Document(
          title: "Serinus + Jaspr",
          head: [
          ],
          body: Home(),
        )
      );
    }
    final file = File('${context.request.path.replaceFirst('/', '')}');
    if(context.request.path.contains('.js')) {
      context.res.contentType = ContentType.parse('text/javascript');
    }
    if(!file.existsSync()) {
      context.res.statusCode = 404;
      return '';
    }
    return file;
  }
}
