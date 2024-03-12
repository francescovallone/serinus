import 'dart:io';

import 'package:serinus/src/commons/extensions/iterable_extansions.dart';

import '../commons/commons.dart';
import './containers/module_container.dart';
import './injector/explorer.dart';
import 'containers/routes_container.dart';
import 'module.dart';
import 'provider.dart';
import 'request_handler.dart';

class SerinusApplication{

  final String host;
  final int port;
  final LogLevel loggingLevel;
  final Module entrypoint;
  bool _enableShutdownHooks = false;
  LoggerService loggerService = LoggerService();

  final Logger _logger = Logger('SerinusApplication');

  SerinusApplication({
    required this.entrypoint,
    this.host = 'localhost',
    this.port = 3000,
    this.loggingLevel = LogLevel.debug,
    LoggerService? loggerService
  }){
    if(loggerService != null){
      this.loggerService = loggerService;
    }
    _initialize(entrypoint);
  }

  String get url => 'http://$host:$port';

  T? get<T extends Provider>(){
    final modulesContainer = ModulesContainer();
    return modulesContainer.get<T>();
  }

  void enableShutdownHooks(){
    if(!_enableShutdownHooks){
      _enableShutdownHooks = true;
      ProcessSignal.sigint.watch().listen((event) async {
        _logger.info('Shutting down server');
        final modulesContainer = ModulesContainer();
        for(final provider in modulesContainer.modules.map((e) => e.providers).flatten()){
          if(provider is OnApplicationShutdown){
            await provider.onApplicationShutdown();
          }
        }
        exit(0);
      });
    }
  }  

  Future<void> serve({
    String poweredByHeader = 'Powered by Serinus',
    SecurityContext? securityContext,
  }) async {
    final server = SerinusHttpServer();
    final modules = ModulesContainer();
    final routes = RoutesContainer();
    _logger.info("Starting server on $host:$port");
    await server.listen(
      securityContext: securityContext,
      poweredByHeader: poweredByHeader,
      (request, response) async {
        try{
          final handler = RequestHandler(routes, modules);
          await handler.handleRequest(request, response);
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

  Future<void> close() async {
    final server = SerinusHttpServer();
    return await server.close();
  }

  Future<void> _initialize(Module module) async {
    final modulesContainer = ModulesContainer();
    await modulesContainer.recursiveRegisterModules(module, module.runtimeType);
    final explorer = Explorer();
    explorer.resolveRoutes();
  }

}