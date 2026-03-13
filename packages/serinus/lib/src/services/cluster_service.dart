import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import '../core/core.dart';


class ClusterMessage {
  final String senderId;
  final String topic;
  final dynamic data;

  const ClusterMessage(this.senderId, this.topic, this.data);
}

class ClusterService extends Provider {
  final SendPort? _orchestrator;
  final ReceivePort _receiver = ReceivePort();
  final StreamController<ClusterMessage> _bus = StreamController.broadcast();
  
  late final String _workerId;

  bool get isWorker => _orchestrator != null;

  ClusterService([this._orchestrator]) {
    // Generate a simple unique ID for this isolate
    _workerId = _receiver.sendPort.hashCode.toString();

    if (isWorker) {
      // Handshake: Send our ID and Port to the Orchestrator
      _orchestrator!.send(['REGISTER', _workerId, _receiver.sendPort]);
      
      // Listen for broadcasts from other isolates
      _receiver.listen((message) {
        if (message is ClusterMessage) {
          _bus.add(message);
        }
      });
    }
  }

  /// Broadcasts data to the entire cluster
  void emit<T>(String topic, T data) {
    if (isWorker) {
      final msg = ClusterMessage(_workerId, topic, data);
      _orchestrator!.send(msg);
    }
  }

  /// Internal stream for the mixin to listen to
  Stream<T> on<T>(String topic) {
    return _bus.stream
        .where((event) => event.topic == topic)
        .map((event) => event.data as T);
  }
}

mixin Syncable<T> on Provider {
  late final ClusterService _clusterService;
  bool _isInitialized = false;

  @internal
  @mustCallSuper
  void initSync(ClusterService clusterService) {
    if (_isInitialized) return;
    
    _clusterService = clusterService;
    _isInitialized = true;
    
    // We use .toString() to ensure cross-isolate safety
    _clusterService.on<T>(runtimeType.toString()).listen(hydrate);
  }

  @mustCallSuper
  void notifyListeners() {
    if (!_isInitialized) return;
    _clusterService.emit<T>(runtimeType.toString(), dehydrate());
  }

  T dehydrate();

  void hydrate(T state);
}