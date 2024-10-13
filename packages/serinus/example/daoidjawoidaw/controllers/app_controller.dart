import '../client.dart';

class AppController {
  AppController(this.client);

  final SerinusClient client;

  final String basePath = '/users';

  Future<String> getUsersDetailsByIdAndName(
    String id,
    String name,
  ) {
    return client.get<String>('$basePath/$id/details/$name');
  }
}
