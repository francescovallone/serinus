import 'package:serinus/serinus.dart';

class BearerHook extends Hook {
  const BearerHook();

  @override
  Future<void> beforeHandle(RequestContext context) async {
    String? authValue = context.headers['authorization'];
    authValue = authValue?.toLowerCase();
    if (authValue == null || !authValue.contains('bearer')) {
      throw UnauthorizedException();
    }
    final String token = authValue.split('bearer ')[1];
    context.add('token', token);
  }
}
