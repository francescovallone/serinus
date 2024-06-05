import 'package:serinus/serinus.dart';
import 'package:serinus/src/services/hook.dart';

class BearerHook extends Hook {

  const BearerHook();

  @override
  Future<void> beforeRequest(Request request, InternalResponse response) async {
    String? authValue = request.headers['authorization'];
    authValue = authValue?.toLowerCase();
    if(authValue == null || !authValue.contains('bearer')) {
      throw UnauthorizedException();
    }
    final String token = authValue.split('bearer ')[1];
    request.addData('token', token);
  }

}