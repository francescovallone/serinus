import 'package:serinus/serinus.dart';

class User {
  final String id;
  final String email;
  final String password;

  User({
    required this.id,
    required this.email,
    required this.password,
  });
}

class UsersService extends Provider {

  final List<User> _users = [
    User(id: '1', email: 'new@example.com', password: 'password'),
    User(id: '2', email: 'hello@example.com', password: 'password'),
  ];

  User? findByEmail(String email) {
    return _users.where((user) => user.email == email).firstOrNull;
  }
}