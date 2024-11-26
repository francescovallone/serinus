import '../client.dart';

class AppController {
  AppController(this.client);

  final SerinusClient client;

  final String basePath = '/users';

  Future<Map<String, Map<String, dynamic>>> getUsers({String? hello}) {
    return client.get<Map<String, Map<String, dynamic>>>(
      '$basePath/',
      queryParameters: {
        'hello': hello,
      },
    );
  }

  Future<String> getUsersDetails(
    String id,
    String name,
    String body,
  ) {
    return client.get<String>('$basePath/$id/details/$name',
        queryParameters: {}, data: body);
  }
}
