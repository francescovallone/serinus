import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/src/auth_guard.dart';

abstract class Policy<T> {
  Future<bool> handle(RequestContext context, T user);
}

// The Authorization Guard
class PolicyGuard<T> extends Guard {
  final Policy<T> policy;

  PolicyGuard(this.policy);

  @override
  Future<bool> canActivate(ExecutionContext context) async {
    if (context.hostType != HostType.http) return true;
    final requestContext = context.switchToHttp();
    final user = requestContext.user<T>();
    return await policy.handle(requestContext, user);
  }
}
