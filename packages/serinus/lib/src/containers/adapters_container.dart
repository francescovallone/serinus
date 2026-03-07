import '../adapters/adapters.dart';

/// The [AdapterContainer] class is used to manage adapters in the application.
/// It allows adding, retrieving, and checking the existence of adapters by their name.
class AdapterContainer {
  final Map<String, Adapter> _adapters = {};

  /// The key for the primary HTTP adapter in the container.
  static const String primaryHttpAdapterKey = 'http';

  /// Adds an adapter to the container.
  Iterable<Adapter> get values => _adapters.values.toSet();

  /// Checks if the container is empty.
  bool get isEmpty => _adapters.isEmpty;

  /// Checks if the container is empty.
  bool get isNotEmpty => _adapters.isNotEmpty;

  /// Adds an adapter to the container.
  void add(Adapter adapter) {
    addAs(adapter.name, adapter);
  }

  /// Adds an adapter to the container using a custom lookup key.
  void addAs(String key, Adapter adapter) {
    if (_adapters.containsKey(key)) {
      throw StateError('Adapter with name $key already exists.');
    }
    _adapters[key] = adapter;
  }

  /// Replaces an existing adapter in the container.
  void replace(String key, Adapter adapter) {
    _adapters[key] = adapter;
  }

  /// Retrieves an adapter by its name.
  T get<T extends Adapter>(String name) {
    final adapter = _adapters[name];
    if (adapter == null) {
      throw StateError('Adapter with name $name not found.');
    }
    return adapter as T;
  }
}
