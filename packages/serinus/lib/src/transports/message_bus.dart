import 'dart:async';
import 'package:uuid/v4.dart';

import 'transport_adapter.dart';
import 'transport_packets.dart';

/// Injectable service to interact with configured transports.
class MessageBus {
  MessageBus(this._adapters);

  final List<TransportAdapter> _adapters;
  final _uuid = UuidV4();

  TransportAdapter? _resolve(String? preferred) {
    if (preferred != null) {
      return _adapters.firstWhere((a) => a.name == preferred, orElse: () => _adapters.first);
    }
    return _adapters.isEmpty ? null : _adapters.first;
  }

  Future<void> emit(String pattern, Object? payload, {Map<String, Object?> headers = const {}, String? adapter}) async {
    final resolved = _resolve(adapter);
    if (resolved == null) return;
    await resolved.emit(EventPacket(pattern: pattern, payload: payload, headers: headers));
  }

  Future<ResponsePacket> send(String pattern, Object? payload, {Duration timeout = const Duration(seconds: 5), Map<String, Object?> headers = const {}, String? adapter}) async {
    final resolved = _resolve(adapter);
    if (resolved == null) {
      throw StateError('No transport adapters configured');
    }
    final request = RequestPacket(pattern: pattern, id: _uuid.generate(), payload: payload, headers: headers);
    final future = resolved.send(request);
    return future.timeout(timeout);
  }
}
