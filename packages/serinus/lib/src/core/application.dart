import 'dart:io';

import '../commons.dart';
import './containers/module_container.dart';
import './injector/explorer.dart';
import 'containers/routes_container.dart';
import 'module.dart';

class SerinusApplication{

  final String host;
  final int port;
  final LogLevel loggingLevel;
  final Module entrypoint;

  SerinusApplication({
    required this.entrypoint,
    this.host = 'localhost',
    this.port = 3000,
    this.loggingLevel = LogLevel.debug,
  }){
    _initialize(entrypoint);
  }

  Future<void> serve({
    String poweredByHeader = 'Powered by Serinus',
    SecurityContext? securityContext,
  }) async {
    final server = SerinusHttpServer();
    final routesContainer = RoutesContainer();
    await server.listen(
      (request, poweredByHeader) async {
        final response = request.response(poweredByHeader: poweredByHeader);
        try{
          final route = routesContainer.getRouteForPath(request.path, request.method.toHttpMethod());
          if(route == null){
            throw NotFoundException(message: 'No route found for path ${request.path} and method ${request.method}');
          }
          await route.controller.handle(request);
        }catch(e){
          if(e is SerinusException){
            final (statusCode, error) = e.handle();
            response.status(statusCode);
            response.send(error);
          }else{
            rethrow;
          }
        }
      },
      errorHandler: (e, stackTrace) {
        print(e);
        print(stackTrace);
      },
    );
  }

  void _initialize(Module module){
    final modulesContainer = ModulesContainer();
    modulesContainer.recursiveRegisterModules(module);
    final explorer = Explorer();
    explorer.explore();
  }

}