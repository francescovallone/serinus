import 'package:auth_jwt/auth/auth_controller.dart';
import 'package:auth_jwt/auth/auth_service.dart';
import 'package:auth_jwt/users/users_module.dart';
import 'package:auth_jwt/users/users_service.dart';
import 'package:serinus/serinus.dart';

class AuthModule extends Module {

  AuthModule() : super(
    imports: [
      UsersModule()
    ],
    controllers: [
      AuthController()
    ],
    providers: [
      Provider.composed<AuthService>(
        (CompositionContext context) async {
          final usersService = context.use<UsersService>();
          return AuthService(usersService);
        },
        inject: [UsersService]
      )
    ]
  );
  
}