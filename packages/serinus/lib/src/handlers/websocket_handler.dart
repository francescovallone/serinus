import '../../serinus.dart';
import '../extensions/iterable_extansions.dart';
import '../http/internal_request.dart';
import 'handler.dart';

/// The [WebSocketHandler] class is used to handle the WebSocket requests.
class WebSocketHandler extends Handler {

  /// The [WebSocketHandler] constructor is used to create a new instance of the [WebSocketHandler] class.
  WebSocketHandler(super.router, super.modulesContainer, super.config);

  @override
  Future<void> handleRequest(
      InternalRequest request, InternalResponse response) async {
    final (:handlers, :onDoneHandlers) = await upgradeRequest(request);
    config.wsAdapter
        ?.listen(handlers, onDone: onDoneHandlers, request: request);
  }

  /// The [upgradeRequest] method is used to upgrade the request when a WebSocket request is received.
  /// 
  /// It takes an [InternalRequest] and returns a [Future] of a [Record] of [WsRequestHandler] and [void Function()].
  /// 
  /// It should not be overridden.
  Future<
      ({
        List<WsRequestHandler> handlers,
        List<void Function()> onDoneHandlers,
      })> upgradeRequest(InternalRequest request) async {
    final providers = modulesContainer.getAll<WebSocketGateway>();
    final onDoneHandlers = <void Function()>[];
    final onMessageHandlers = <WsRequestHandler>[];
    for (final provider in providers) {
      if (provider.path != null && !request.uri.path.endsWith(provider.path!)) {
        continue;
      }
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
          Request(request),
          provider.serializer);
      config.wsAdapter?.addContext(request.webSocketKey, context);
      if (provider is OnClientConnect) {
        provider.onClientConnect();
      }
      var onDone =
          provider is OnClientDisconnect ? provider.onClientDisconnect : null;
      if (onDone != null) {
        onDoneHandlers.add(onDone);
      }
      onMessageHandlers.add((dynamic message, WebSocketContext context) {
        if (provider.deserializer != null) {
          message = provider.deserializer?.deserialize(message);
        }
        return provider.onMessage(message, context);
      });
    }
    if (onMessageHandlers.isEmpty) {
      throw NotFoundException(
          message: 'No WebSocketGateway found for this request');
    }
    await config.wsAdapter?.upgrade(request);
    return (
      handlers: onMessageHandlers,
      onDoneHandlers: onDoneHandlers,
    );
  }
}
