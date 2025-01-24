import 'package:serinus/serinus.dart';
import 'package:serinus_sse/serinus_sse.dart';

class SseHandler extends Handler {
  
  SseHandler(super.router, super.modulesContainer, super.config);

  @override
  Future<void> handleRequest(InternalRequest request, InternalResponse response) async {
    final adapter = config.adapters[SseAdapter] as SseAdapter?;
    if(adapter == null) {
      throw InternalServerErrorException(message: 'SseAdapter is not registered');
    }
    final providers = modulesContainer.getAll<SseProvider>();
    final clientId = request.queryParameters['sseClientId'];
    if (request.method == 'GET' && request.headers['accept'] == 'text/event-stream') {
      final sseProviders = createContexts(
        request.uri.path
      );
      if(sseProviders.isEmpty) {
        throw NotFoundException(message: 'The requested path can\'t be handled by any provider');
      }
      if (clientId == null) {
        throw BadRequestException(message: 'Client id is required to establish a connection');
      }
      final sink = await adapter.initializeChannel(request);
      if(adapter.hasConnection(clientId)) {
        adapter.acceptReconnection(clientId, sink);
      } else {
        final connection = SseConnection(sink);
        adapter.addConnection(clientId, connection);
        adapter.addConnectionController(connection);
      }
      sseProviders.whereType<OnSseConnect>().forEach((e) {
        e.onConnect(clientId).listen((event) {
          adapter.send(event, clientId);
        });
      });
    }
    if (request.method == 'POST' && request.headers['accept'] == 'text/event-stream') {
      if(clientId == null) {
        throw BadRequestException(message: 'Client id is required to handle incoming messages');
      }
      await adapter.addIncomingMessage(request, response, clientId, providers);
    }
  }

  String normalizePath(String path) {
    final startsWith = path.startsWith('/'),  endsWith = path.endsWith('/');
    switch([startsWith, endsWith]) {
      case [true, true]:
        return path.substring(0, path.length - 1);
      case [true, false]:
        return path;
      case [false, true]:
        return '/${path.substring(0, path.length - 1)}';
      case [false, false]:
        return '/$path';
    }
    return path;
  }

  Iterable<SseProvider> createContexts(String requestPath) {
        final providers = modulesContainer.getAll<SseProvider>().where((e) {
          final providerPath = normalizePath(e.path);
          print(providerPath);
          return providerPath == requestPath;
        });
        final adapter = config.adapters[SseAdapter]! as SseAdapter;
    for (final provider in providers) {
      final providerModule =
          modulesContainer.getModuleByProvider(provider.runtimeType);
      final injectables = modulesContainer
          .getModuleInjectablesByToken(modulesContainer.moduleToken(providerModule));
      final scopedProviders = List<Provider>.from(
          injectables.providers.addAllIfAbsent(modulesContainer.globalProviders));
      scopedProviders.remove(provider);
      final context = SseContext(
          adapter, {
        for (final provider in scopedProviders) provider.runtimeType: provider
      }, config.hooks.services);
      adapter.addContext(provider.runtimeType, context);
    }
    return providers;
  }

}