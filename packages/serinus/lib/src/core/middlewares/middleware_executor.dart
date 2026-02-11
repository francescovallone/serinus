import 'dart:async';

import '../../containers/pool_manager.dart';
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
    if (middlewares.isEmpty) {
      return;
    }
    final delegate = PoolManager.acquireDelegate();
    final length = middlewares.length;
    try {
      for (int i = 0; i < length; i++) {
        final middleware = middlewares.elementAt(i);
        await middleware.use(context, delegate);
        if (delegate.completed) {
          if (delegate.response != null) {
            await onDataReceived(delegate.response!);
          }
          return; // Stop the chain
        }
        if (response.isClosed) {
          return;
        }
      }
    } finally {
      PoolManager.releaseDelegate(delegate);
    }
  }
}
