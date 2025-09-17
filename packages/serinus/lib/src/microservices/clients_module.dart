import '../core/core.dart';
import 'microservices.dart';


class ClientsModule extends Module {

  final List<TransportClient> clients;

  ClientsModule([this.clients = const []]);

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    print('Connecting to microservice clients... $clients');
    for (var client in clients) {
      await client.connect();
    }
    return DynamicModule(
      providers: [...clients],
      exports: [...clients.map((c) => c.runtimeType)],
    );
  }

}