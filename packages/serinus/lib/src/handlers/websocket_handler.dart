import '../adapters/adapters.dart';
import '../contexts/contexts.dart';
import '../core/core.dart';
import '../exceptions/exceptions.dart';
import '../http/http.dart';
import '../mixins/mixins.dart';
import 'handler.dart';

/// Type to define the record used to save an handler that will be called when a client disconnects.
typedef DisconnectHandler = ({void Function(String)? onDone, String clientId});

/// The [WebSocketHandler] class is used to handle the WebSocket requests.
class WebSocketHandler extends Handler {
  /// The [WebSocketHandler] constructor is used to create a new instance of the [WebSocketHandler] class.
  WebSocketHandler(super.router, super.modulesContainer, super.config);

  @override
  Future<void> handleRequest(
      InternalRequest request, InternalResponse response) async {
    final (:handlers, :onDoneHandlers) = await upgradeRequest(request);
    (config.adapters[WsAdapter] as WsAdapter?)
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
        List<DisconnectHandler> onDoneHandlers,
      })> upgradeRequest(InternalRequest request) async {
    final providers = modulesContainer.getAll<TypedWebSocketGateway>();
    final onDoneHandlers = <DisconnectHandler>[];
    final onMessageHandlers = <WsRequestHandler>[];
    for (final provider in providers) {
      if (provider.path != null && !request.uri.path.endsWith(provider.path!)) {
        continue;
      }
      final providerModule =
          modulesContainer.getScopeByProvider(provider.runtimeType);
      final scopedProviders = providerModule.providers;
      scopedProviders.remove(provider);
      final context = WebSocketContext(
          (config.adapters[WsAdapter] as WsAdapter?)!,
          request.webSocketKey,
          {
            for (final provider in scopedProviders)
              provider.runtimeType: provider
          },
          config.hooks.services,
          Request(request),
          provider.serializer);
      (config.adapters[WsAdapter] as WsAdapter?)
          ?.addContext(request.webSocketKey, context);
      if (provider is OnClientConnect) {
        provider.onClientConnect(request.webSocketKey);
      }
      provider.server = (config.adapters[WsAdapter] as WsAdapter?);
      var onDone =
          provider is OnClientDisconnect ? provider.onClientDisconnect : null;
      if (onDone != null) {
        onDoneHandlers.add((onDone: onDone, clientId: request.webSocketKey));
      }
      onMessageHandlers.add((dynamic message, WebSocketContext context) {
        return provider.onMessage(
          provider.deserializer.deserialize(message),
          context
        );
      });
    }
    if (onMessageHandlers.isEmpty) {
      throw NotFoundException(
          message: 'No WebSocketGateway found for this request');
    }
    await (config.adapters[WsAdapter] as WsAdapter?)?.upgrade(request);
    return (
      handlers: onMessageHandlers,
      onDoneHandlers: onDoneHandlers,
    );
  }
}
