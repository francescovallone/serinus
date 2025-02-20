import 'package:frontier/frontier.dart';
import 'package:serinus/serinus.dart';

class FrontierModule extends Module {

  final List<Strategy> strategies;
  final void Function([Exception? exception])? onError;

  FrontierModule(this.strategies, {this.onError});

  @override
  Future<Module> registerAsync(ApplicationConfig config) async {
    config.addHook(FrontierHook(strategies, onError: onError));
    return this;
  }

}

class FrontierHook extends Hook with OnBeforeHandle {

  final List<Strategy> strategies;
  final void Function([Exception? exception])? onError;

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

class GuardMeta extends Metadata<String> {

  GuardMeta(String strategy): super(
    name: 'GuardMeta', 
    value: strategy
  );

}