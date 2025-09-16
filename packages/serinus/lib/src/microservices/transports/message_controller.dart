import 'package:uuid/v4.dart';

import '../../contexts/rpc_context.dart';
import '../../core/controller.dart';
import '../../core/route.dart';

/// Type definition for a message handler function.
typedef MessageHandler = Future<dynamic> Function(RpcContext context);

/// Type definition for an event handler function.
typedef EventHandler = Future<void> Function(RpcContext context);

/// Declarative registration for message/event handlers (MVP skeleton).
mixin RpcController on Controller {
  final _uuid = UuidV4();

  /// Registered message routes and their handlers.
  final Map<String, ({RpcRoute route, MessageHandler handler})> messageRoutes =
      {};

  /// Registered event routes and their handlers.
  final Map<String, ({RpcRoute route, EventHandler handler})> eventRoutes = {};

  /// Register a message handler for the given [route].
  void onMessage(RpcRoute route, MessageHandler handler) {
    if (messageRoutes.values.any((r) => r.route.path == route.path)) {
      throw StateError(
        'A message route with pattern "${route.path}" is already registered in the controller.',
      );
    }
    if (eventRoutes.values.any((r) => r.route == route)) {
      throw StateError(
        'A message route cannot have the same pattern as an event route: "${route.path}".',
      );
    }
    messageRoutes[_uuid.generate()] = (route: route, handler: handler);
  }

  /// Register an event handler for the given [route].
  void onEvent(RpcRoute route, EventHandler handler) {
    if (messageRoutes.values.any((r) => r.route == route)) {
      throw StateError(
        'A message route with pattern "${route.path}" is already registered in the controller.',
      );
    }
    eventRoutes[_uuid.generate()] = (route: route, handler: handler);
  }
}
