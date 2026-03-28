import '../contexts/contexts.dart';
import 'hook.dart';

/// Guards are used to determine whether a request should be allowed to proceed or not. They can be used for authentication, authorization, or any other kind of request validation.
abstract class Guard implements Processable {

  /// Determines whether the request should be allowed to proceed or not.
  Future<bool> canActivate(ExecutionContext context);

}