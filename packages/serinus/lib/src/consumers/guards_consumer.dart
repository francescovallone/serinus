import 'dart:async';

import '../contexts/execution_context.dart';
import '../core/core.dart';
import '../exceptions/exceptions.dart';
import 'consumer.dart';

class GuardsConsumer extends ExecutionContextConsumer<Guard, bool> {
  GuardsConsumer(super.request, super.routeData, super.providers,
      {super.body, super.context});

  @override
  ExecutionContext createContext() {
    final builder = ExecutionContextBuilder();
    if (body != null) {
      builder.body = body!;
    }
    builder.addProviders(providers);
    return builder.build(request);
  }

  @override
  Future<bool> consume(Iterable<Guard> consumables) async {
    context ??= createContext();
    for (final consumable in consumables) {
      final canActivate = await consumable.canActivate(context!);
      if (!canActivate) {
        throw ForbiddenException(
            message:
                '${consumable.runtimeType} block the access to the route ${request.path}');
      }
    }
    return true;
  }
}
