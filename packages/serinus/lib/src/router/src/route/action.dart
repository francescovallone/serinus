part of '../tree/node.dart';

/// A typedef representing an indexed value.
typedef Indexed<T> = ({int index, T value});

/// An abstract interface class for storing and managing handlers.
abstract interface class HandlerStore<T> {
  /// Retrieves the handler associated with the given HTTP method.
  Indexed<T>? getHandler(HttpMethod method);

  /// An iterable of HTTP methods that have associated handlers.
  Iterable<HttpMethod> get methods;

  /// Offsets the indices of all stored handlers by the given index.
  void offsetIndex(int index);

  /// Checks if there is a handler for the given HTTP method.
  bool hasMethod(HttpMethod method);

  /// Adds a route handler for the given HTTP method.
  void addRoute(HttpMethod method, Indexed<T> handler);

  /// Adds a middleware handler.
  void addMiddleware(Indexed<T> handler);
}

/// A mixin that provides implementation for the HandlerStore interface.
mixin HandlerStoreMixin<T> implements HandlerStore<T> {
  /// The list of middleware handlers.
  final List<Indexed<T>> middlewares = [];

  /// The list of request handlers for each HTTP method.
  final requestHandlers = List<Indexed<T>?>.filled(
    HttpMethod.values.length,
    null,
  );

  @override
  void offsetIndex(int index) {
    for (final middleware in middlewares.indexed) {
      middlewares[middleware.$1] = (
        index: middleware.$2.index + index,
        value: middleware.$2.value,
      );
    }

    // Offset the indices of request handlers
    for (int i = 0; i < requestHandlers.length; i++) {
      if (requestHandlers[i] != null) {
        requestHandlers[i] = (
          index: requestHandlers[i]!.index + index,
          value: requestHandlers[i]!.value,
        );
      }
    }
  }

  @override
  Iterable<HttpMethod> get methods => HttpMethod.values.where(hasMethod);

  @override
  bool hasMethod(HttpMethod method) => requestHandlers[method.index] != null;

  @override
  Indexed<T>? getHandler(HttpMethod method) =>
      requestHandlers[method.index] ?? requestHandlers[HttpMethod.all.index];

  @override
  void addRoute(HttpMethod method, Indexed<T> handler) {
    if (hasMethod(method)) {
      final route = (this as Node).route;
      throw ArgumentError.value(
          '${method.name}: $route', null, 'Route entry already exists');
    }
    requestHandlers[method.index] = handler;
  }

  @override
  void addMiddleware(Indexed<T> handler) => middlewares.add(handler);
}
