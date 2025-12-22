import 'dart:async';

import '../../contexts/contexts.dart';
import '../../http/http.dart';
import '../../utils/wrapped_response.dart';
import '../core.dart';

/// Executes a series of middleware functions.
class MiddlewareExecutor {
  /// Executes the middleware functions in the given [middlewares] iterable.
  Future<void> execute(
    Iterable<Middleware> middlewares,
    ExecutionContext context,
    OutgoingMessage response, {
    required Future<void> Function(WrappedResponse data) onDataReceived,
  }) async {
    final completer = Completer<void>();
    if (middlewares.isEmpty) {
      return;
    }
    final middlewareList =
        middlewares is List<Middleware> ? middlewares : middlewares.toList();
    final length = middlewareList.length;
    for (int i = 0; i < length; i++) {
      final middleware = middlewareList[i];
      await middleware.use(context, ([data]) async {
        if (data != null) {
          final responseData = data is WrappedResponse
              ? data
              : WrappedResponse(data);
          await onDataReceived(responseData);
          return;
        }
        if (i == length - 1) {
          completer.complete();
        }
      });
      if (response.isClosed && !completer.isCompleted) {
        completer.complete();
        break;
      }
    }
    return completer.future;
  }
}
