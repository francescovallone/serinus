import 'package:auth_jwt/auth/auth_service.dart';
import 'package:serinus/serinus.dart';

class AuthController extends Controller {
  AuthController() : super('/auth') {
    on(
      Route.post(
        '/login',
        pipes: {
          BodySchemaValidationPipe(
            object({
              'email': string().notEmpty().email(),
              'password': string().notEmpty(),
            })
          )
        }
      ),
      (RequestContext<Map<String, dynamic>> context) async {
        final authService = context.use<AuthService>();
        final result = authService.authenticate(context.body);
        return result;
      },
    );
  }
}