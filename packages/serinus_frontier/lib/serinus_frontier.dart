import 'package:frontier/frontier.dart';
import 'package:serinus/serinus.dart';

export 'package:frontier/frontier.dart';

/// The [FrontierModule] class is used to register strategies in the application.
///
/// It is the main class of the library. It is used to define and use strategies.
class FrontierModule extends Module {
  /// The [strategies] to be used.
  final List<Strategy> strategies;

  /// The [onError] function to be called when an error occurs.
  final void Function([Exception? exception])? onError;

  /// Create a new instance of [FrontierModule].
  FrontierModule(this.strategies, {this.onError});

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    config.globalHooks.addHook(FrontierHook(strategies, onError: onError));
    return DynamicModule();
  }
}

/// The [FrontierHook] class is used to authenticate requests using strategies.
class FrontierHook extends Hook with OnBeforeHandle {
  /// The [strategies] to be used.
  final List<Strategy> strategies;

  /// The [onError] function to be called when an error occurs.
  final void Function([Exception? exception])? onError;

  /// Create a new instance of [FrontierHook].
  FrontierHook(this.strategies, {this.onError}) {
    for (final strategy in strategies) {
      service.use(strategy);
    }
  }

  final _frontier = Frontier();

  @override
  Frontier get service => _frontier;

  @override
  Future<void> beforeHandle(ExecutionContext context) async {
    if (context.hostType != HostType.http) {
      return;
    }
    final requestContext = context.switchToHttp();
    final hasStrategy = requestContext.canStat('GuardMeta');
    if (!hasStrategy) {
      return;
    }
    final stringHeaders = Map<String, String>.fromEntries(
      requestContext.headers.asFullMap().entries.map(
        (e) => MapEntry(e.key, e.value.toString()),
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
        (e) => MapEntry(e.key, e.value.join(',')),
      ),
    );
    final strategyRequest = StrategyRequest(
      headers: stringHeaders,
      body: requestContext.body,
      query: stringQuery,
      cookies: stringCookies,
    );
    final strategyName = hasStrategy
        ? requestContext.stat<String?>('GuardMeta')
        : strategies.first.name;
    final value = await service.authenticate(
      strategyName ?? strategies.first.name,
      strategyRequest,
    );
    if (value == null) {
      if (onError != null) {
        onError!.call();
        return;
      }
      throw UnauthorizedException();
    }
    if (value is Exception) {
      if (onError != null) {
        onError!.call(value);
        return;
      }
      throw UnauthorizedException('Unauthorized! - ${value.toString()}');
    }
    requestContext['frontier_response'] = value;
  }
}

/// The [GuardMeta] class is used to define the strategy to be used.
class GuardMeta extends Metadata<String?> {
  /// Create a new instance of [GuardMeta].
  GuardMeta([String? strategy]) : super(name: 'GuardMeta', value: strategy);
}
