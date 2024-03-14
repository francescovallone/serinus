import 'dart:async';

import 'contexts/execution_context.dart';

abstract class Guard {

  const Guard();

  FutureOr<bool> canActivate(ExecutionContext context);

}