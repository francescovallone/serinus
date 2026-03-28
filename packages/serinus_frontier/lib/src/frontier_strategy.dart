import 'package:serinus/serinus.dart';
import 'package:serinus_frontier/serinus_frontier.dart';

abstract class FrontierStrategy<T, P> extends Provider {
  /// The name of the strategy, used for identification.
  String get name;

  /// The actual strategy implementation that will be used for authentication.
  Strategy get strategy;

  /// Validates a request based on the provided [RequestContext] and payload.
  /// Returns a Future that resolves to the authenticated user or throws an error if authentication fails.
  Future<T?> validate(RequestContext context, P payload);
}
