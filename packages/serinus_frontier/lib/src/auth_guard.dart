import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/serinus_frontier.dart';

/// The [AuthGuard] class authenticates requests using Frontier strategies.
class AuthGuard<T extends FrontierStrategy> extends Guard {
  /// Create a new instance of [AuthGuard].
  AuthGuard();

  @override
  Future<bool> canActivate(ExecutionContext context) async {
    if (context.hostType != HostType.http) {
      return true;
    }

    final requestContext = context.switchToHttp();
    if (!requestContext.canUse<T>()) {
      throw StateError('Strategy "$T" is not registered as a Provider.');
    }

    final frontierStrategy = requestContext.use<T>();
    final service = Frontier()..use(frontierStrategy.strategy);
    final Object? frontierResult;
    try {
      frontierResult = await service.authenticate(
        frontierStrategy.strategy.name,
        _buildStrategyRequest(requestContext),
      );
    } catch (e) {
      return false;
    }
    if (frontierResult == null || frontierResult is Exception) {
      return false;
    }
    try {
      final user = await frontierStrategy.validate(
        requestContext,
        frontierResult,
      );

      if (user == null) return false;

      requestContext['user'] = user;
      return true;
    } catch (e) {
      return false;
    }
  }

  StrategyRequest _buildStrategyRequest(RequestContext requestContext) {
    final stringHeaders = Map<String, String>.unmodifiable(
      requestContext.headers.asFullMap(),
    );
    final stringQuery = <String, String>{
      for (final entry in requestContext.query.entries)
        entry.key: switch (entry.value) {
          Iterable<dynamic> iterable => iterable.join(','),
          null => '',
          _ => entry.value.toString(),
        },
    };
    final stringCookies = Map<String, String>.unmodifiable(
      Map<String, String>.fromEntries(
        requestContext.request.cookies.map(
          (entry) => MapEntry(entry.name, entry.value),
        ),
      ),
    );

    return StrategyRequest(
      headers: stringHeaders,
      body: requestContext.body,
      query: stringQuery,
      cookies: stringCookies,
    );
  }
}

extension FrontierUser on RequestContext {
  T user<T>() {
    final user = this['user'];
    if (user == null) {
      throw StateError(
        'No user found in request context. Make sure to use AuthGuard and that the strategy returns a valid user.',
      );
    }
    return this['user'] as T;
  }
}
