import 'dart:async';

import '../../containers/pool_manager.dart';
import '../../utils/wrapped_response.dart';

/// This class acts as the 'next' function.
/// It is pooled, so we allocate it once and reuse it forever.
class MiddlewareDelegate implements Poolable {
  /// The response to be sent, if any.
  WrappedResponse? response;
  /// Whether the middleware chain has been completed.
  bool completed = false;

  /// Private constructor to prevent external instantiation.
  MiddlewareDelegate(); // Internal use for Pool

  /// This is the function passed as 'next' to middlewares.
  /// It returns synchronously-completed Futures to avoid async overhead.
  Future<void> call([dynamic data]) async {
    if (data != null) {
      response = data is WrappedResponse ? data : WrappedResponse(data);
      completed = true;
    }
  }

  @override
  void reset() {
    response = null;
    completed = false;
  }
}