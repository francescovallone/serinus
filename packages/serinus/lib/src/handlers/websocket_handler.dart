import 'package:serinus/src/mixins/mixins.dart';

import '../adapters/adapters.dart';
import '../core/core.dart';
import '../core/websockets/ws_context.dart';
import '../extensions/iterable_extansions.dart';
import '../http/http.dart';
import '../http/internal_request.dart';
import 'handler.dart';

class WebSocketHandler extends Handler {

  WebSocketHandler(super.router, super.modulesContainer, super.config);

  @override
  Future<void> handleRequest(InternalRequest request, InternalResponse response) async {
    final (:handlers, :onDoneHandlers) = await upgradeRequest(request);
    config.wsAdapter?.listen(handlers, onDone: onDoneHandlers, request: request);
  }

  Future<({
    List<WsRequestHandler> handlers,
    List<void Function()> onDoneHandlers,
  })> upgradeRequest(InternalRequest request) async {
    final providers = modulesContainer.getAll<WebSocketGateway>();
    await config.wsAdapter?.upgrade(request);
    final onDoneHandlers = <void Function()>[];
    final onMessageHandlers = <WsRequestHandler>[];
    for (final provider in providers) {
      final providerModule =
          modulesContainer.getModuleByProvider(provider.runtimeType);
      final injectables = modulesContainer.getModuleInjectablesByToken(
          providerModule.token.isEmpty
              ? providerModule.runtimeType.toString()
              : providerModule.token);
      final scopedProviders = List<Provider>.from(injectables.providers
          .addAllIfAbsent(modulesContainer.globalProviders));
      scopedProviders.remove(provider);
      final context = WebSocketContext(
          config.wsAdapter!,
          request.webSocketKey,
          {
            for (final provider in scopedProviders)
              provider.runtimeType: provider
          },
          Request(request));
      config.wsAdapter?.addContext(request.webSocketKey, context);
      if (provider is OnClientConnect) {
        provider.onClientConnect();
      }
      var onDone =
          provider is OnClientDisconnect ? provider.onClientDisconnect : null;
      if (onDone != null) {
        onDoneHandlers.add(onDone);
      }
      onMessageHandlers.add(provider!.onMessage);
    }
    return (
      handlers: onMessageHandlers,
      onDoneHandlers: onDoneHandlers,
    );
  }

}