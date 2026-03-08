import 'package:frontier/frontier.dart';
import 'package:serinus/serinus.dart';

export 'package:frontier/frontier.dart';

const frontierResponseKey = 'frontier_response';

/// Signature for authentication error callbacks.
typedef FrontierOnError = void Function([Exception? exception]);

/// The [FrontierModule] class registers Frontier strategies as value providers.
class FrontierModule extends Module {
  /// The [strategies] available to [AuthGuard] instances.
  final List<Strategy> strategies;

  /// Create a new instance of [FrontierModule].
  FrontierModule(List<Strategy> strategies)
    : strategies = List<Strategy>.unmodifiable(strategies),
      super(
        providers: [
          Provider.forValue<List<Strategy>>(
            List<Strategy>.unmodifiable(strategies),
          ),
          ...strategies.map(
            (strategy) => Provider.forValue<Strategy>(
              strategy,
              name: strategy.name,
            ),
          ),
        ],
        exports: [
          List<Strategy>,
          ...strategies.map((strategy) => Export.value<Strategy>(strategy.name)),
        ],
      );
}

/// The [AuthGuard] class authenticates requests using Frontier strategies.
class AuthGuard extends Guard {
  /// The strategy name to authenticate with.
  final String? strategy;

  /// The callback to invoke when authentication fails.
  final FrontierOnError? onError;

  /// Create a new instance of [AuthGuard].
  AuthGuard(this.strategy, {this.onError});

  @override
  Future<bool> canActivate(ExecutionContext context) async {
    if (context.hostType != HostType.http) {
      return true;
    }

    final requestContext = context.switchToHttp();
    final strategies = _resolveStrategies(requestContext);
    final strategyName = strategy ?? strategies.first.name;
    final selectedStrategy = _resolveStrategy(
      requestContext,
      strategies,
      strategyName,
    );
    final service = Frontier()..use(selectedStrategy);
    final value = await service.authenticate(
      strategyName,
      _buildStrategyRequest(requestContext),
    );

    if (value == null) {
      onError?.call();
      return false;
    }

    if (value is Exception) {
      onError?.call(value);
      return false;
    }

    requestContext[frontierResponseKey] = value;
    return true;
  }

  List<Strategy> _resolveStrategies(RequestContext requestContext) {
    if (!requestContext.canUse<List<Strategy>>()) {
      throw StateError(
        'No Frontier strategies found in the request context. '
        'Import FrontierModule in the current module before using AuthGuard.',
      );
    }

    final strategies = requestContext.use<List<Strategy>>();
    if (strategies.isEmpty) {
      throw StateError('No Frontier strategies have been registered.');
    }
    return strategies;
  }

  Strategy _resolveStrategy(
    RequestContext requestContext,
    List<Strategy> strategies,
    String strategyName,
  ) {
    if (requestContext.canUse<Strategy>(strategyName)) {
      return requestContext.use<Strategy>(strategyName);
    }

    for (final strategy in strategies) {
      if (strategy.name == strategyName) {
        return strategy;
      }
    }

    throw StateError('Frontier strategy "$strategyName" is not registered.');
  }

  StrategyRequest _buildStrategyRequest(RequestContext requestContext) {
    final stringHeaders = Map<String, String>.fromEntries(
      requestContext.headers.asFullMap().entries.map(
        (entry) => MapEntry(entry.key, entry.value.toString()),
      ),
    );
    final stringQuery = <String, String>{
      for (final entry in requestContext.query.entries)
        entry.key: switch (entry.value) {
          Iterable<dynamic> iterable => iterable.join(','),
          null => '',
          _ => entry.value.toString(),
        },
    };
    final stringCookies = Map<String, String>.fromEntries(
      requestContext.request.session.all.entries.map(
        (entry) => MapEntry(entry.key, entry.value.join(',')),
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
