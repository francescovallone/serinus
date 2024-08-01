import 'dart:math';

import 'package:serinus/serinus.dart';

import 'exception.dart';
import 'storage.dart';

class RateLimiterHook extends Hook {
  /// Maximum number of requests.
  int maxRequests;

  /// Rate limiter instance.
  ClientRateLimiter? rateLimiter;

  /// Duration of the rate limiter.
  final Duration duration;

  /// Storage instance.
  final Storage storage = Storage();

  /// RateLimiterHook constructor.
  RateLimiterHook(
      {int? maxRequests, this.duration = const Duration(minutes: 1)})
      : maxRequests = maxRequests ?? double.infinity.toInt();

  @override
  Future<void> onRequest(Request request, InternalResponse response) async {
    final key = getKey(request);
    rateLimiter = storage.get(key) ?? storage.add(key, duration);
    final result = rateLimiter!.resetAt.compareTo(DateTime.now()) > 0;
    switch ([result, rateLimiter!.count < maxRequests]) {
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
  Future<void> onResponse(dynamic data, ResponseProperties properties) async {
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
