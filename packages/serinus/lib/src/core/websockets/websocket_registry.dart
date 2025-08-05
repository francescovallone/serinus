import 'dart:io';

import 'package:spanner/spanner.dart';

import '../../adapters/adapters.dart';
import '../../contexts/contexts.dart';
import '../../errors/initialization_error.dart';
import '../../mixins/mixins.dart';
import '../../services/logger_service.dart';
import '../../utils/wrapped_response.dart';
import '../core.dart';

/// The [WebsocketRegistry] class is responsible for managing WebSocket connections and gateways.
/// It registers WebSocket gateways, handles their initialization, and manages the lifecycle of WebSocket connections
class WebsocketRegistry extends Provider with OnApplicationReady, OnApplicationShutdown {
  
  final Logger _logger = Logger('WebSocketRegistry');

  final Map<int, WsAdapter> _adapters = {};

  final ApplicationConfig _config;

  /// The [WebsocketRegistry] constructor initializes the registry with the provided application configuration.
  WebsocketRegistry(this._config);

  @override
  Future<void> onApplicationReady() async {
    final wsAdapter = _config.adapters.get<WebSocketAdapter>('websocket');
    await wsAdapter.init(_config);
    final gateways = _config.modulesContainer.getAll<WebSocketGateway>();
    final mainPort = wsAdapter.httpAdapter.port;
    for (final gateway in gateways) {
      if (gateway.port == null || gateway.port == mainPort) {
        final router = wsAdapter.router ?? Spanner();
        final gatewayScope = _config.modulesContainer.getScopeByProvider(gateway.runtimeType);
        final result = router.lookup(HTTPMethod.ALL, gateway.path ?? '/');
        if(result?.values.isNotEmpty ?? false) {
          throw InitializationError(
            'WebSocket Gateway with path "${gateway.path ?? '/'}" already exists. '
            'Please use a different path or port for the gateway.',
          );
        }
        _logger.info('WebSocket Gateway listening on port ${gateway.port ?? mainPort} with path "${gateway.path ?? '*'}"');
        router.addRoute(
          HTTPMethod.ALL, 
          gateway.path ?? '/', 
          GatewayScope(
            gateway,
            {
              for (final provider in gatewayScope.providers)
                if (provider.runtimeType != gateway.runtimeType)
                  provider.runtimeType: provider,
            },
            gateway.hooks.merge([_config.globalHooks]),
          )
        );
        wsAdapter.router ??= router;
      } else {
        final WsAdapter customWsAdapter;
        if (_adapters.containsKey(gateway.port!)) {
          customWsAdapter = _adapters[gateway.port!]!;
        } else {
          final differentPortAdapter = SerinusHttpAdapter(
            host: wsAdapter.httpAdapter.host,
            port: gateway.port!,
            poweredByHeader: wsAdapter.httpAdapter.poweredByHeader,
            securityContext: wsAdapter.httpAdapter.securityContext,
          );
          await differentPortAdapter.init(_config);
          differentPortAdapter.listen(onRequest: (request, response) async {
            differentPortAdapter.reply(
              response,
              WrappedResponse(''),
              ResponseContext({}, {})..statusCode = 200..contentType = ContentType.text,
            );
          });
          customWsAdapter = WebSocketAdapter(
            differentPortAdapter,
          );
          await customWsAdapter.init(_config);
          _adapters[gateway.port!] = customWsAdapter;
        }
        final router = customWsAdapter.router ?? Spanner();
        final gatewayScope = _config.modulesContainer.getScopeByProvider(gateway.runtimeType);
        final result = router.lookup(HTTPMethod.ALL, gateway.path ?? '/');
        if(result?.values.isNotEmpty ?? false) {
          throw InitializationError(
            'WebSocket Gateway with path "${gateway.path ?? '*'}" already exists. '
            'Please use a different path or port for the gateway.',
          );
        }
        _logger.info('WebSocket Gateway listening on port ${gateway.port} with path "${gateway.path ?? '*'}"');
         // Register the gateway with the custom adapter's router
        router.addRoute(
          HTTPMethod.ALL,
          gateway.path ?? '*',
          GatewayScope(
            gateway,
            {
              for (final provider in gatewayScope.providers) 
                if(provider.runtimeType != gateway.runtimeType) 
                  provider.runtimeType: provider,
            },
            gateway.hooks.merge([_config.globalHooks]),
          )
        );
        customWsAdapter.router ??= router;
      }
    }
  }

  @override
  Future<void> onApplicationShutdown() async {
    await _config.adapters.get<WebSocketAdapter>('websocket').close();
    for (final adapter in _adapters.values) {
      await adapter.close();
    }
  }
  
  @override
  bool get isGlobal => false;

}