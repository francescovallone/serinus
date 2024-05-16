import 'dart:async';

import '../../serinus.dart';
import '../contexts/execution_context.dart';
import 'consumer.dart';

class GuardsConsumer extends ExecutionContextConsumer<Guard, bool> {
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
