import 'dart:io';

import 'package:meta/meta.dart';
import 'package:serinus/src/commons/commons.dart';
import 'package:serinus/src/commons/errors/initialization_error.dart';
import 'package:serinus/src/commons/extensions/iterable_extansions.dart';
import 'package:serinus/src/core/consumers/request_handler.dart';
import 'package:serinus/src/core/containers/module_container.dart';
import 'package:serinus/src/core/containers/router.dart';
import 'package:serinus/src/core/core.dart';
import 'package:serinus/src/core/injector/explorer.dart';

sealed class Application {

  final String host;
  final int port;
  final LogLevel level;
  final Module entrypoint;
  bool _enableShutdownHooks = false;
  LoggerService? loggerService;
  ModulesContainer modulesContainer = ModulesContainer();
  Router router = Router();
  final Adapter serverAdapter;

  Application({
    required this.entrypoint,
    required this.serverAdapter,
    this.host = 'localhost',
    this.port = 3000,
    this.level = LogLevel.debug,
    LoggerService? loggerService,
  }){
    this.loggerService = loggerService ?? LoggerService(level: level);
  }

  String get url;

  T? get<T extends Provider>(){
    return modulesContainer.get<T>();
  }

  void enableShutdownHooks(){
    if(!_enableShutdownHooks){
      _enableShutdownHooks = true;
      ProcessSignal.sigint.watch().listen((event) async {
        await shutdown();
      });
    }
  }

  @internal
  Future<void> initialize();

  @internal
  Future<void> shutdown();

  Future<void> serve();

  Future<void> close();

}

class SerinusApplication extends Application {

  ViewEngine? viewEngine;
  Cors? _cors;
  final Logger _logger = Logger('SerinusApplication');

  SerinusApplication({
    required super.entrypoint,
    required super.serverAdapter,
    super.host = 'localhost',
    super.port = 3000,
    super.level,
    super.loggerService,
  }) {
    initialize();
  }

  @override
  String get url => 'http://$host:$port';

  void enableCors(Cors cors){
    _cors = cors;
  }
  
  void useViewEngine(ViewEngine viewEngine){
    this.viewEngine = viewEngine;
  }

  @override
  Future<void> serve() async {
    try{
      _logger.info("Starting server on $host:$port");
      await serverAdapter.listen(
        (request, response) async {
          final handler = RequestHandler(router, modulesContainer, _cors);
          await handler.handleRequest(request, response, viewEngine: viewEngine);
        },
        errorHandler: (e, stackTrace) {
          print(e);
          print(stackTrace);
        },
      );
    } on SocketException catch(_) {
      _logger.severe('Failed to start server on $host:$port');
      await close();
    }
  }

  @override
  Future<void> close() async {
    await serverAdapter.close();
    await shutdown();
  }
  
  @override
  Future<void> initialize() async {
    if(entrypoint is DeferredModule){
      throw InitializationError(
        'The entry point of the application cannot be a DeferredModule'
      );
    }
    await modulesContainer.registerModules(entrypoint, entrypoint.runtimeType);
    await modulesContainer.finalize();
    final explorer = Explorer(
      modulesContainer,
      router
    );
    explorer.resolveRoutes();
  }
  
  @override
  Future<void> shutdown() async {
    _logger.info('Shutting down server');
    final registeredProviders = modulesContainer.modules.map((e) => e.providers).flatten();
    for(final provider in registeredProviders){
      if(provider is OnApplicationShutdown){
        await provider.onApplicationShutdown();
      }
    }
    if(String.fromEnvironment('SERINUS_TEST', defaultValue: 'false') == 'true'){
      exit(0);
    }
  }

}