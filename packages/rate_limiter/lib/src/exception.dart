import 'package:serinus/serinus.dart';

/// Exception thrown when rate limit is exceeded.
class TooManyRequests extends SerinusException {
  /// Constructor.
  const TooManyRequests(
      {super.message = '', super.statusCode = 429});
}
