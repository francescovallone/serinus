import 'dart:async';

import '../contexts/execution_context.dart';

abstract class Guard {
  const Guard();

  Future<bool> canActivate(ExecutionContext context);
}
