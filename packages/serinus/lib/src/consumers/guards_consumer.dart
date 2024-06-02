import 'dart:async';

import '../../serinus.dart';
import '../contexts/execution_context.dart';
import 'consumer.dart';

/// The [GuardsConsumer] class is used to consume the guards.
class GuardsConsumer extends ExecutionContextConsumer<Guard, bool> {
  /// The constructor of the [GuardsConsumer] class.
  GuardsConsumer(super.requestContext, {super.context});

  @override
  ExecutionContext createContext(RequestContext context) {
    final builder = ExecutionContextBuilder();
    return builder.fromRequestContext(context);
  }

  @override
  Future<bool> consume(Iterable<Guard> consumables) async {
    context ??= createContext(requestContext);
    for (final consumable in consumables) {
      final canActivate = await consumable.canActivate(context!);
      if (!canActivate) {
        throw ForbiddenException(
            message:
                '${consumable.runtimeType} block the access to the route ${requestContext.path}');
      }
    }
    return true;
  }
}
