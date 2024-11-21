import 'dart:math';

import '../contexts/contexts.dart';
import '../core/core.dart';
import '../exceptions/exceptions.dart';
import '../http/http.dart';
import '../mixins/mixins.dart';

/// The [RateLimiterHook] class is a hook that limits the number of requests a client can make.
class RateLimiterHook extends Hook with OnRequestResponse {
  /// Maximum number of requests.
  int maxRequests;

  /// Rate limiter instance.
  ClientRateLimiter? rateLimiter;

  /// Duration of the rate limiter.
  final Duration duration;

  /// Storage instance.
  final RateStorage storage = RateStorage();

  /// RateLimiterHook constructor.
  RateLimiterHook(
      {int? maxRequests, this.duration = const Duration(minutes: 1)})
      : maxRequests = maxRequests ?? double.infinity.toInt();

  @override
  Future<void> onRequest(Request request, InternalResponse response) async {
    final key = getKey(request);
    rateLimiter = storage.get(key) ?? storage.add(key, duration);
    final result = rateLimiter!.resetAt.compareTo(DateTime.now()) > 0;
    switch ([result, rateLimiter!.count <= maxRequests]) {
      case [true, true]:
        rateLimiter!.updateCount();
        return;
      case [false, _]:
        rateLimiter!.reset(duration);
        return;
    }
    throw RateLimitExceeded();
  }

  /// Get the key from the request.
  ///
  /// If the request has the header 'X-Forwarded-For' it will return the value of the header.
  /// Otherwise, it will return the remote address of the client.
  String getKey(Request request) {
    return request.headers['X-Forwarded-For'] ??
        request.clientInfo?.remoteAddress.address;
  }

  @override
  Future<void> onResponse(Request request, dynamic data, ResponseProperties properties) async {
    if (properties.statusCode < 400 && rateLimiter != null) {
      properties.headers.addAll({
        'X-RateLimit-Limit': '$maxRequests',
        'X-RateLimit-Remaining': '${max(maxRequests - rateLimiter!.count, 0)}',
        'X-RateLimit-Reset':
            '${(rateLimiter!.resetAt.millisecondsSinceEpoch / 1000).ceil()}',
      });
    }
  }
}

/// The [RateStorage] class is used by the [RateLimiterHook] to store the rate limiters.
class RateStorage {
  final Map<String, ClientRateLimiter> _rateLimiters = {};

  /// Add a new rate limiter to the storage.
  ///
  /// If the rate limiter already exists, it will update the count.
  ClientRateLimiter add(String key, Duration duration) {
    if (_rateLimiters.containsKey(key)) {
      updateCount(key);
      return _rateLimiters[key]!;
    }
    final item = ClientRateLimiter(key: key, duration: duration);
    _rateLimiters[key] = item;
    return item;
  }

  /// Get a rate limiter from the storage.
  ClientRateLimiter? get(String key) {
    return _rateLimiters[key];
  }

  /// Update the count of a rate limiter.
  void updateCount(String key) {
    if (_rateLimiters.containsKey(key)) {
      _rateLimiters[key]!.updateCount();
    }
  }
}

/// The [ClientRateLimiter] class is used to store the rate limit information.
class ClientRateLimiter {
  /// The key of the rate limiter.
  final String key;

  /// The time when the rate limiter will reset.
  DateTime resetAt;

  /// The number of requests made.
  int count;

  /// The [ClientRateLimiter] constructor is used to create a new instance of the [ClientRateLimiter] class.
  ClientRateLimiter({required this.key, required Duration duration, int? count})
      : resetAt = DateTime.now().add(duration),
        count = count ?? 1;

  /// Update the count of the rate limiter.
  void updateCount() {
    ++count;
  }

  /// Reset the rate limiter.
  void reset(Duration duration) {
    resetAt = DateTime.now().add(duration);
    count = 1;
  }
}
