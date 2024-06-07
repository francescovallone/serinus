import 'dart:async';

import '../../serinus.dart';
import 'consumer.dart';

/// The [GuardsConsumer] class is used to consume the guards.
class GuardsConsumer extends ContextConsumer<Guard, bool> {
  /// The constructor of the [GuardsConsumer] class.
  GuardsConsumer(super.context);

  @override
  Future<bool> consume(Iterable<Guard> consumables) async {
    for (final consumable in consumables) {
      final canActivate = await consumable.canActivate(context);
      if (!canActivate) {
        throw ForbiddenException(
            message:
                '${consumable.runtimeType} block the access to the route ${context.path}');
      }
    }
    return true;
  }
}
