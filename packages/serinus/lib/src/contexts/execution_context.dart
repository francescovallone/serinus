import '../core/core.dart';
import '../http/http.dart';
import 'request_context.dart';

/// The [ExecutionContext] class is used to create the execution context.
sealed class ExecutionContext {
  /// The [providers] property contains the providers of the execution context.
  final Map<Type, Provider> providers;

  /// The [request] property contains the request of the context.
  final Request request;

  ExecutionContext(this.providers, this.request);

  /// This method is used to retrieve a provider from the context.
  T use<T>() {
    if (!providers.containsKey(T)) {
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }

  /// This method is used to add data to the request.
  void addDataToRequest(String key, dynamic value) {
    request.addData(key, value);
  }
}

class _ExecutionContextImpl extends ExecutionContext {
  _ExecutionContextImpl(super.providers, super.request);

  @override
  T use<T>() {
    if (!providers.containsKey(T)) {
      throw StateError('Provider not found in request context');
    }
    return providers[T] as T;
  }
}

/// The [ExecutionContextBuilder] class is used to create the execution context builder.
final class ExecutionContextBuilder {
  /// The [providers] property contains the providers of the execution context.
  Map<Type, Provider> providers = {};

  /// This method is used to add providers to the execution context.
  ExecutionContextBuilder addProviders(Iterable<Provider> providers) {
    this.providers.addAll({
      for (var provider in providers) provider.runtimeType: provider,
    });
    return this;
  }

  /// This method is used to build the execution context from the request context.
  ExecutionContext fromRequestContext(RequestContext context) {
    return _ExecutionContextImpl(context.providers, context.request);
  }

  /// This method is used to build the execution context.
  ExecutionContext build(Request request) {
    return _ExecutionContextImpl(providers, request);
  }
}
