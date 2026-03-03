import '../core/middlewares/middleware_delegate.dart';

/// Manages object pools for reusable objects.
class PoolManager {
  static final ObjectPool<MiddlewareDelegate> _delegatePool = ObjectPool(
    () => MiddlewareDelegate(),
  );

  /// Acquires a MiddlewareDelegate from the pool.
  static MiddlewareDelegate acquireDelegate() {
    return _delegatePool.acquire();
  }

  /// Releases a MiddlewareDelegate back to the pool.
  static void releaseDelegate(MiddlewareDelegate delegate) {
    _delegatePool.release(delegate);
  }
}

/// A generic object pool for reusable objects.
class ObjectPool<T extends Poolable> {
  final List<T> _pool = [];
  final T Function() _factory;
  final int _maxSize;

  /// Creates an ObjectPool with the given [factory] function to create new instances.
  ObjectPool(this._factory, {int initialSize = 50, int maxSize = 10000})
    : _maxSize = maxSize {
    for (var i = 0; i < initialSize; i++) {
      _pool.add(_factory());
    }
  }

  /// Acquires an object from the pool.
  T acquire() {
    if (_pool.isEmpty) {
      return _factory();
    }
    return _pool.removeLast();
  }

  /// Releases an object back to the pool.
  void release(T item) {
    if (_pool.length < _maxSize) {
      item.reset();
      _pool.add(item);
    }
  }
}

/// An interface for poolable objects.
class Poolable {
  /// Resets the object's state for reuse.
  void reset() {}
}
