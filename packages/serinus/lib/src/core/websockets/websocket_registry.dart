import 'dart:io';

import 'package:spanner/spanner.dart';

import '../../../serinus.dart';
import '../../adapters/adapters.dart';
import '../../containers/module_container.dart';
import '../../errors/initialization_error.dart';
import '../../mixins/mixins.dart';
import '../../utils/wrapped_response.dart';
import '../core.dart';

class WebsocketRegistry extends Provider with OnApplicationReady, OnApplicationShutdown {

  final Logger logger = Logger('WebSocketRegistry');

  final Map<String, WebSocket> server = {};

  final Map<int, WsAdapter> adapters = {};

  final ApplicationConfig config;

  WebsocketRegistry(this.config);

  @override
  Future<void> onApplicationReady() async {
    final wsAdapter = config.adapters.get<WebSocketAdapter>('websocket');
    await wsAdapter.init(config);
    final modulesContainer = ModulesContainer();
    final gateways = modulesContainer.getAll<WebSocketGateway>();
    final mainPort = wsAdapter.httpAdapter.port;
    for (final gateway in gateways) {
      if (gateway.port == null || gateway.port == mainPort) {
        final router = wsAdapter.router ?? Spanner();
        final gatewayScope = modulesContainer.getScopeByProvider(gateway.runtimeType);
        final result = router.lookup(HTTPMethod.ALL, gateway.path ?? '*');
        if(result?.values.isNotEmpty ?? false) {
          throw InitializationError(
            'WebSocket Gateway with path "${gateway.path ?? '*'}" already exists. '
            'Please use a different path or port for the gateway.',
          );
        }
        logger.info('WebSocket Gateway listening on port ${gateway.port ?? mainPort} with path "${gateway.path ?? '*'}"');
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
            gateway.hooks.merge([config.globalHooks]),
          )
        );
        wsAdapter.router ??= router;
      } else {
        final WsAdapter customWsAdapter;
        if (adapters.containsKey(gateway.port!)) {
          customWsAdapter = adapters[gateway.port!]!;
        } else {
          final differentPortAdapter = SerinusHttpAdapter(
            host: wsAdapter.httpAdapter.host,
            port: gateway.port!,
            poweredByHeader: wsAdapter.httpAdapter.poweredByHeader,
            securityContext: wsAdapter.httpAdapter.securityContext,
          );
          await differentPortAdapter.init(config);
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
          await customWsAdapter.init(config);
          adapters[gateway.port!] = customWsAdapter;
        }
        final router = customWsAdapter.router ?? Spanner();
        final gatewayScope = modulesContainer.getScopeByProvider(gateway.runtimeType);
        final result = router.lookup(HTTPMethod.ALL, gateway.path ?? '*');
        if(result?.values.isNotEmpty ?? false) {
          throw InitializationError(
            'WebSocket Gateway with path "${gateway.path ?? '*'}" already exists. '
            'Please use a different path or port for the gateway.',
          );
        }
        logger.info('WebSocket Gateway listening on port ${gateway.port} with path "${gateway.path ?? '*'}"');
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
            gateway.hooks.merge([config.globalHooks]),
          )
        );
        customWsAdapter.router ??= router;
      }
    }
  }

  @override
  Future<void> onApplicationShutdown() async {
    await config.adapters.get<WebSocketAdapter>('websocket').close();
    for (final adapter in adapters.values) {
      await adapter.close();
    }
  }
  
  @override
  bool get isGlobal => false;

}