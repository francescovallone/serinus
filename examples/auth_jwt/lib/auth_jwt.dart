import 'dart:convert';

import 'package:auth_jwt/auth/auth_module.dart';
import 'package:frontier_jwt/frontier_jwt.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_config/serinus_config.dart';
import 'package:serinus_frontier/serinus_frontier.dart';
import 'test/test_module.dart';

class AppController extends Controller {
  AppController() : super('/') {
    on<String, dynamic>(Route.get('/'), (RequestContext context) async {
      return 'Hello World - ${jsonEncode(context['frontier_response'])}';
    });
  }

  @override
  List<Metadata> get metadata => [
        GuardMeta('jwt'),
      ];
}

class AppModule extends Module {
  AppModule()
      : super(imports: [
          ConfigModule(),
          Module.composed((CompositionContext context) async {
            final configService = context.use<ConfigService>();
            return FrontierModule([
              JwtStrategy(
                  JwtStrategyOptions(
                      SecretKey(configService.getOrNull('JWT_SECRET') ??
                          'default_secret'),
                      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken()),
                  (options, jwt, done) async {
                final decodedJwt = jwt as JWT;
                return done(decodedJwt.payload);
              })
            ]);
          }, inject: [ConfigService]),
          AuthModule(),
        ], controllers: [
          AppController()
        ]);

  @override
  List<Module> get imports => [
        ...super.imports,
        TestModule(),
      ];
}

Future<void> bootstrap() async {
  final app = await serinus.createApplication(entrypoint: AppModule());
  await app.serve();
}
