# Authentication

Authentication is essential when developing an application. Serinus provides a powerful and flexible authentication system through the `serinus_frontier` package, which allows you to easily implement various authentication strategies, such as JWT, OAuth, or custom token-based authentication.

In this section, we will explore how to set up authentication in your Serinus application using the `serinus_frontier` package with a simple example of JWT authentication.

## Creating an Authentication Module

We will start by generating a new module for authentication using the Serinus CLI:

```bash
serinus generate module auth
serinus generate controller auth
serinus generate provider auth
```

Let's also create a simple `User` model for demonstration purposes:

```dart
class User {
  final String id;
  final String username;
  final String password;

  User({required this.id, required this.username, required this.password});
}
```

And let's also create the module and the provider that will handle users:

```bash
serinus generate module users
serinus generate provider users
```

Now for the sake of simplicity, we will use an in-memory user store. In a real application, you would typically use a database to store user information.

```dart
import 'package:serinus/serinus.dart';

class UsersProvider extends Provider{
  final List<User> _users = [
	User(id: '1', username: 'user1', password: 'password1'),
	User(id: '2', username: 'user2', password: 'password2'),
  ];

  User? findByUsername(String username) {
	return _users.firstWhere((user) => user.username == username, orElse: () => null);
  }
}
```

Let's export the `UsersProvider` from the `UsersModule`:

```dart
import 'package:serinus/serinus.dart';

import 'users_provider.dart';

class UsersModule extends Module {
  UsersModule() : super(
	providers: [UsersProvider()],
	exports: [UsersProvider],
  );
}
```

Now we can set up the `AuthModule` to use the `UsersProvider` and configure the JWT authentication strategy.

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/serinus_frontier.dart';
import '../users/users_module.dart';

class AuthModule extends Module {
  AuthModule() : super(
	imports: [UsersModule()],
	providers: [
		Provider.composed<AuthProvider>(
			(CompositionContext context) => AuthProvider(context.use<UsersProvider>()),
			inject: [UsersProvider],
		)
	],
	controllers: [AuthController()],
  );
}
```

## Implementing the Authentication Logic

Next, we will implement the `AuthProvider` that will handle the authentication logic, including validating user credentials and generating JWT tokens.

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/serinus_frontier.dart';
import '../users/users_provider.dart';

class AuthProvider extends Provider {

  final UsersProvider _usersProvider;

  AuthProvider(this._usersProvider);

  Map<String, dynamic> authenticate(Map<String, dynamic> credentials) {
    final user = _usersProvider.findByUsername(credentials['username']);
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
        'username': user.username,
      },
      issuer: 'serinus',
    );
    return jwt.sign(SecretKey('default_secret'));
  }

}
```

Finally, we will implement the `AuthController` to expose an endpoint for authentication:

```dart
import 'package:serinus/serinus.dart';

class AuthController extends Controller {
  final AuthProvider _authProvider;

  AuthController(this._authProvider) {
	on(Route.post('/login'), _login);
  }

  Future<Map<String, dynamic>> _login(RequestContext context) async {
	final credentials = await context.bodyAs<Map<String, dynamic>>();
	final authResult = _authProvider.authenticate(credentials);
	return authResult;
  }
}
```

With this setup, you can now send a POST request to `/auth/login` with a JSON body containing the username and password to receive a JWT token if the credentials are valid.

This is just a basic example to get you started with authentication in Serinus. The `serinus_frontier` package provides many more features and options for customizing your authentication strategy, such as token expiration, refresh tokens, and support for different authentication schemes. Be sure to check the documentation for more details on how to use these features effectively in your application.