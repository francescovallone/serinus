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
  Future<Module> registerAsync(ApplicationConfig config) async {
    config.addHook(FrontierHook(strategies, onError: onError));
    return this;
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
    for(final strategy in strategies) {
      service.use(strategy);
    }
  }

  final _frontier = Frontier();

  @override
  Frontier get service => _frontier;

  @override
  Future<void> beforeHandle(RequestContext context) async {
    final hasStrategy = context.canStat('GuardMeta');
    if(!hasStrategy) {
      return;
    }
    final stringHeaders = Map<String, String>.fromEntries(context.headers.entries.map((e) => MapEntry(e.key, e.value.toString())));
    final stringQuery = Map<String, String>.fromEntries(context.query.entries.map((e) => MapEntry(e.key, e.value.join(','))));
    final stringCookies = Map<String, String>.fromEntries(context.request.session.all.entries.map((e) => MapEntry(e.key, e.value.join(','))));
    final strategyRequest = StrategyRequest(
      headers: stringHeaders, 
      body: context.body.value, 
      query: stringQuery, 
      cookies: stringCookies
    );
    final strategyName = context.stat<String>('GuardMeta');
    final value = await service.authenticate(
      strategyName, 
      strategyRequest
    );
    if(value == null) {
      if(onError != null) {
        onError!.call();
        return;
      }
      throw UnauthorizedException();
    }
    if(value is Exception) {
      if(onError != null) {
        onError!.call(value);
        return;
      }
      throw UnauthorizedException(message: 'Unauthorized! - ${value.toString()}');
    }
    context['frontier_response'] = value;
  }

}

/// The [GuardMeta] class is used to define the strategy to be used.
class GuardMeta extends Metadata<String> {

  /// Create a new instance of [GuardMeta].
  GuardMeta(String strategy): super(
    name: 'GuardMeta', 
    value: strategy
  );

}