class Storage {
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
