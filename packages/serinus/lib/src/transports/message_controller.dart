import 'package:uuid/v4.dart';

import '../core/controller.dart';
import 'transport_packets.dart';

typedef MessageHandler = Future<dynamic> Function(RequestPacket packet);
typedef EventHandler = Future<void> Function(EventPacket packet);

/// Declarative registration for message/event handlers (MVP skeleton).
mixin RpcController on Controller {

  final _uuid = UuidV4();

  final Map<String, ({String pattern, MessageHandler handler})> _messageRoutes = {};
  final Map<String, ({String pattern, EventHandler handler})> _eventRoutes = {};

  void onMessage(String pattern, MessageHandler handler) {
    _messageRoutes[_uuid.generate()] = (
      pattern: pattern,
      handler: handler,
    );
  }

  void onEvent(String pattern, EventHandler handler) {
    _eventRoutes[_uuid.generate()] = (
      pattern: pattern,
      handler: handler,
    );
  }

}