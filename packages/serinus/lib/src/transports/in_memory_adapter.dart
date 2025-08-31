import 'dart:async';

import 'package:spanner/spanner.dart';

import '../core/application_config.dart';
import 'transport_adapter.dart';
import 'transport_packets.dart';

/// Simple in-memory transport for local development & tests.
class InMemoryTransportAdapter extends TransportAdapter<Null> {
  final _incomingController = StreamController<IncomingMessagePacket>.broadcast();
  final _subscriptions = <String>{};
  bool _open = false;

  @override
  String get name => 'inmemory';

  @override
  bool get isOpen => _open;

  @override
  Stream<IncomingMessagePacket> get incoming => _incomingController.stream;

  @override
  Future<void> emit(EventPacket event) async {
    if (_subscriptions.contains(event.pattern)) {
      _incomingController.add(IncomingEvent(event));
    }
  }

  @override
  Future<ResponsePacket> send(RequestPacket request) async {
    if (!_subscriptions.contains(request.pattern)) {
      // Simulate no handler scenario.
      return ResponsePacket(
        pattern: request.pattern,
        id: request.id,
        payload: {'error': 'NO_HANDLER'},
        headers: const {},
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isError: true,
      );
    }
    final completer = Completer<ResponsePacket>();
    // Temporary listener for matching response id.
    late StreamSubscription sub;
    sub = _incomingController.stream.listen((packet) {
      if (packet is IncomingRequest) return; // ignore requests
      if (packet is IncomingEvent) return; // ignore events
    });
    // For in-memory MVP we directly invoke handler by re-dispatching as request.
    _incomingController.add(IncomingRequest(request));
    // There is no automatic response generation yet (handled by dispatcher later).
    // So we complete with a timeout error until dispatcher responds.
    return completer.future.timeout(const Duration(seconds: 5), onTimeout: () {
      sub.cancel();
      return ResponsePacket(
        pattern: request.pattern,
        id: request.id,
        payload: {'error': 'TIMEOUT'},
        isError: true,
        headers: const {},
      );
    });
  }

  /// Framework dispatcher will call this to push a produced response.
  void pushResponse(ResponsePacket response) {
    _incomingController.addStream(Stream.value(
      // We can introduce IncomingResponse class later if needed; for now reuse event wrapper not ideal.
      // TODO: refine response channel abstraction.
      // Using a cast hack: treat response as event is not clean; create proper wrapper soon.
      IncomingEvent(EventPacket(pattern: response.pattern, payload: response.payload, id: response.id)),
    ));
  }

  @override
  Future<void> subscribe(String pattern) async {
    _subscriptions.add(pattern);
  }

  @override
  Future<void> init(ApplicationConfig config) async {
    _open = true;
  }

  @override
  Future<void> close() async {
    _open = false;
    await _incomingController.close();
  }

  @override
  Spanner router = Spanner();
}
