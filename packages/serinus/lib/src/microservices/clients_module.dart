import '../core/core.dart';
import 'microservices.dart';

/// Module to register and manage microservice clients.
class ClientsModule extends Module {
  /// List of transport clients to be registered.
  final List<TransportClient> clients;

  /// Constructor for the [ClientsModule].
  ClientsModule([this.clients = const []]);

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    for (var client in clients) {
      await client.connect();
    }
    return DynamicModule(
      providers: [...clients],
      exports: [...clients.map((c) => c.runtimeType)],
    );
  }
}
