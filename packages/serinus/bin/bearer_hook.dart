// coverage:ignore-file
import 'package:serinus/serinus.dart';

class BearerHook extends Hook with OnRequestResponse {
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
    final jsonBody = request.body?.json;
    if (jsonBody != null) {
      if (jsonBody.multiple) {
        final List<dynamic> list = jsonBody.value;
        for (final item in list) {
          if (item is Map<String, dynamic> && item.containsKey(body)) {
            request['bearer'] = item[body];
            break;
          }
        }
      } else if (jsonBody.value.containsKey(body)) {
        request['bearer'] = jsonBody.value[body];
      }
    }
    return;
  }
}
