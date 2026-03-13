import 'dart:async';
import 'dart:isolate';

import 'package:meta/meta.dart';

import '../core/core.dart';


/// The [ClusterMessage] class represents a message that is sent between worker isolates in the cluster. It contains the sender's worker ID, the topic of the message, and the data payload. This class is used to facilitate communication and synchronization between workers by allowing them to emit and listen for messages on specific topics.
class ClusterMessage {
  /// The ID of the worker that sent the message. This is used to identify the source of the message and can be useful for debugging or for implementing features that require knowledge of which worker sent a particular message.
  final String senderId;
  /// The topic of the message, which is used to categorize the message and allow workers to listen for specific types of messages. Workers can subscribe to specific topics and will only receive messages that match those topics, enabling efficient communication and synchronization across the cluster.
  final String topic;
  /// The data payload of the message, which can be of any type. This is the actual content of the message that will be sent to other workers in the cluster. The data can contain any information that needs to be shared between workers, such as state updates, commands, or any other relevant information.
  final dynamic data;

  /// The constructor for the [ClusterMessage] class initializes the message with the sender's worker ID, the topic, and the data payload. This allows for easy creation of messages that can be sent between workers in the cluster, facilitating communication and synchronization across the different isolates.
  const ClusterMessage(this.senderId, this.topic, this.data);
}

/// The [ClusterService] class is responsible for managing communication between worker isolates in a cluster. It allows workers to emit messages to each other and listen for messages on specific topics, enabling synchronization and coordination across the cluster. The service also provides a mechanism for sending control messages to the orchestrator, which can be used for tasks like graceful shutdowns or health checks.
class ClusterService extends Provider {
  final SendPort? _orchestrator;
  final ReceivePort _receiver = ReceivePort();
  final StreamController<ClusterMessage> _bus = StreamController.broadcast();
  final StreamController<String> _controlBus = StreamController.broadcast(); // NEW

  /// The [ClusterService] constructor initializes the cluster service by setting up communication channels with the orchestrator and other worker isolates. If an orchestrator is provided, it registers the worker with the orchestrator and starts listening for incoming messages from both the orchestrator and other workers in the cluster. The worker ID is either provided or generated based on the receive port's send port hash code to ensure uniqueness across the cluster.
  late final String workerId;

  /// The [isWorker] getter checks if the current instance of the ClusterService is running in a worker isolate by verifying if the _orchestrator send port is not null. If _orchestrator is null, it indicates that this instance is not connected to an orchestrator and therefore is not a worker in the cluster.
  bool get isWorker => _orchestrator != null;

  /// The [ClusterService] constructor initializes the cluster service by setting up communication channels with the orchestrator and other worker isolates. If an orchestrator is provided, it registers the worker with the orchestrator and starts listening for incoming messages from both the orchestrator and other workers in the cluster. The worker ID is either provided or generated based on the receive port's send port hash code to ensure uniqueness across the cluster.
  ClusterService([this._orchestrator, String? id]) {
    workerId = id ?? _receiver.sendPort.hashCode.toString();

    if (isWorker) {
      _orchestrator!.send(['REGISTER', workerId, _receiver.sendPort]);
      
      _receiver.listen((message) {
        if (message is ClusterMessage) {
          _bus.add(message);
        } else if (message is String) { // Handle Control Messages
          _controlBus.add(message);
        }
      });
    }
  }

  /// Emit a message to all workers in the cluster. The [topic] parameter is used to categorize the message, and the [data] parameter contains the payload that will be sent to other workers. Only workers that are listening for the specified topic will receive the message.
  void emit<T>(String topic, T data) {
    if (isWorker) {
      final msg = ClusterMessage(workerId, topic, data);
      _orchestrator!.send(msg);
    }
  }

  /// Listen for messages on a specific topic. The [topic] parameter is used to filter messages, and the returned stream will only emit messages that match the specified topic.
  Stream<T> on<T>(String topic) {
    return _bus.stream
        .where((event) => event.topic == topic)
        .map((event) => event.data as T);
  }

  /// Send a control message to the orchestrator, which can be used for commands like graceful shutdown, health checks, etc.
  Stream<String> get onControlMessage => _controlBus.stream;
}

/// A mixin that can be applied to any provider to make it synchronizable across a cluster of worker isolates. Providers that use this mixin will automatically synchronize their state with other instances of the same provider in different workers, allowing for a consistent state across the entire cluster.
mixin Syncable<T> on Provider {
  late final ClusterService _clusterService;
  bool _isInitialized = false;

  @internal
  @mustCallSuper
  /// Initializes the synchronization mechanism for the provider. This method should be called in the worker entrypoint to set up the connection with the ClusterService and start listening for state updates from other workers in the cluster.
  void initSync(ClusterService clusterService) {
    if (_isInitialized) {
      return;
    }
    
    _clusterService = clusterService;
    _isInitialized = true;
    
    // We use .toString() to ensure cross-isolate safety
    _clusterService.on<T>(runtimeType.toString()).listen(hydrate);
  }

  @mustCallSuper
  /// Call this method whenever the state changes to notify other workers in the cluster.
  void notifyListeners() {
    if (!_isInitialized) {
      return;
    }
    _clusterService.emit<T>(runtimeType.toString(), dehydrate());
  }

  /// This method should return the current state of the provider, which will be sent to other workers in the cluster.
  T dehydrate();

  /// This method will be called when a state update is received from another worker in the cluster. The [state] parameter will contain the new state that should be applied to this provider.
  void hydrate(T state);
}