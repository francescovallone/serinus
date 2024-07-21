// coverage:ignore-file
import 'package:serinus/serinus.dart';

class BearerHook extends Hook {
  final String header;

  final String body;

  final String query;

  const BearerHook({
    this.header = 'Bearer',
    this.body = 'access_token',
    this.query = 'access_token',
  });

  @override
  Future<void> onRequest(Request request, InternalResponse response) async {
    final String? authValue = request.headers['authorization'];
    if (request.body == null) {
      await request.parseBody();
    }
    if (authValue?.startsWith(header) ?? false) {
      request['bearer'] = authValue!.substring(header.length + 1);
    }
    if (request.query.containsKey('access_token')) {
      request['bearer'] = request.query['access_token'];
    }
    if (request.body?.containsKey('access_token') ?? false) {
      request['bearer'] = request.body?['access_token'];
    }
    return;
  }
}
