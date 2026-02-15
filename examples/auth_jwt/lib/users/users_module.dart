import 'package:auth_jwt/users/users_controller.dart';
import 'package:auth_jwt/users/users_service.dart';
import 'package:serinus/serinus.dart';

class UsersModule extends Module {

  UsersModule() : super(
    controllers: [
      UsersController()
    ],
    providers: [
      UsersService()
    ],
    exports: [
      UsersService
    ]
  );
  
}