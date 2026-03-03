import 'package:auth_jwt/users/users_service.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:serinus/serinus.dart';

class AuthService extends Provider {

  final UsersService _usersService;

  AuthService(this._usersService);

  Map<String, dynamic> authenticate(Map<String, dynamic> credentials) {
    final user = _usersService.findByEmail(credentials['email']);
    if (user == null || user.password != credentials['password']) {
      throw Exception('Invalid credentials');
    }
    final token = _generateToken(user);
    return {
      'token': token,
    };
  }

  String _generateToken(User user) {
    final jwt = JWT(
      {
        'id': user.id,
        'email': user.email,
      },
      issuer: 'serinus',
    );
    return jwt.sign(SecretKey('default_secret'));
  }

}