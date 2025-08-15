import '../core/core.dart';
import 'injection_token.dart';
import 'serinus_container.dart';

/// The [MiddlewaresContainer] class is used to track the middlewares used in the application
class MiddlewaresContainer {

  final SerinusContainer container;

  final Map<InjectionToken, List<Middleware>> _middlewares = {};

  MiddlewaresContainer(this.container);

  

}