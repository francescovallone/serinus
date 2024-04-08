import 'dart:io';

import 'package:serinus/src/commons/commons.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';
import 'package:serinus/src/core/consumers/request_handler.dart';
import 'package:serinus/src/core/containers/module_container.dart';
import 'package:serinus/src/core/containers/routes_container.dart';
import 'package:serinus/src/core/core.dart';
import 'package:serinus/src/core/injector/explorer.dart';

class SerinusApplication{

  final String host;
  final int port;
  final LogLevel loggingLevel;
  final Module entrypoint;
  bool _enableShutdownHooks = false;
  LoggerService loggerService = LoggerService();
  final HttpServerAdapter serverAdapter;
  ViewEngine? viewEngine;
  final Logger _logger = Logger('SerinusApplication');

  SerinusApplication({
    required this.entrypoint,
    required this.serverAdapter,
    this.host = 'localhost',
    this.port = 3000,
    this.loggingLevel = LogLevel.debug,
    LoggerService? loggerService,
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
        await _shutdownApplication();
      });
    }
  }
  
  void useViewEngine(ViewEngine viewEngine){
    this.viewEngine = viewEngine;
  }

  Future<void> serve() async {
    try{
      final modules = ModulesContainer();
      final routes = RoutesContainer();
      _logger.info("Starting server on $host:$port");
      await this.serverAdapter.listen(
        (request, response) async {
          try{
            final handler = RequestHandler(routes, modules);
            await handler.handleRequest(request, response, viewEngine: viewEngine);
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
    } on SocketException catch(_) {
      _logger.severe('Failed to start server on $host:$port');
      await this.close();
    }
  }

  Future<void> close() async {
    final server = SerinusHttpServer();
    await server.close();
    await _shutdownApplication();
  }

  Future<void> _shutdownApplication() async {
    _logger.info('Shutting down server');
    final modulesContainer = ModulesContainer();
    for(final provider in modulesContainer.modules.map((e) => e.providers).flatten()){
      if(provider is OnApplicationShutdown){
        await provider.onApplicationShutdown();
      }
    }
    exit(0);
  }

  Future<void> _initialize(Module module) async {
    final modulesContainer = ModulesContainer();
    await modulesContainer.recursiveRegisterModules(module, module.runtimeType);
    await modulesContainer.finalize();
    final explorer = Explorer();
    explorer.resolveRoutes();
  }

}