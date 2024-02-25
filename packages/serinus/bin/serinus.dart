import 'package:serinus/src/commons.dart';
import 'package:serinus/src/commons/request.dart';
import 'package:serinus/src/core.dart';


class GetRoute extends Route {
  GetRoute({
    required super.path, 
    super.method = HttpMethod.get
  });

  @override
  Future<void> handle(InternalRequest request, Response response) async {
    await Future.delayed(Duration(seconds: 5));
    response.status(201).text('Hello world');
  }
}

class PostRoute extends Route {
  PostRoute({
    required super.path, 
    super.method = HttpMethod.post
  });

  @override
  Future<void> handle(InternalRequest request, Response response) async {
    response.status(201).text('Hello world');
  }
}

class HomeController extends Controller {
  HomeController() : super(path: '/'){
    on(GetRoute(path: '/'), (route) {
      print('Hello world');
    });
    on(PostRoute(path: '/'), (route) {
      print('Hello world');
    });
  }
}

class AppModule extends Module {
  AppModule() : super(
    controllers: [
      HomeController()
    ]
  );
}

void main(List<String> arguments) async {
  print(arguments);
  SerinusApplication application = SerinusApplication(
    entrypoint: AppModule(), 
  );
  print("Starting application...");
  await application.serve();
}