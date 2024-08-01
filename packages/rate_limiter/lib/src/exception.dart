import 'package:serinus/serinus.dart';

/// Exception thrown when rate limit is exceeded.
class RateLimitExceeded extends SerinusException {
  /// Constructor.
  const RateLimitExceeded(
      {super.message = 'Rate limit exceeded', super.statusCode = 429});
}
