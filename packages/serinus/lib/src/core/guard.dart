import 'dart:async';

import '../contexts/execution_context.dart';

/// The [Guard] class is used to define a guard.
abstract class Guard {
  /// The [Guard] constructor is used to create a new instance of the [Guard] class.
  const Guard();

  /// The [canActivate] method is used to check if the guard can activate.
  Future<bool> canActivate(ExecutionContext context);
}
