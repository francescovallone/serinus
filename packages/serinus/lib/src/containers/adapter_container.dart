import '../adapters/adapters.dart';

/// The [AdapterContainer] class is used to manage adapters in the application.
/// It allows adding, retrieving, and checking the existence of adapters by their name.
class AdapterContainer {

  final Map<String, Adapter> _adapters = {};

  /// Adds an adapter to the container.
  Iterable<Adapter> get values => _adapters.values;

  /// Checks if the container is empty.
  bool get isEmpty => _adapters.isEmpty;

  /// Checks if the container is empty.
  bool get isNotEmpty => _adapters.isNotEmpty;

  /// Adds an adapter to the container.
  void add(Adapter adapter) {
    if (_adapters.containsKey(adapter.name)) {
      throw StateError('Adapter with name ${adapter.name} already exists.');
    }
    _adapters[adapter.name] = adapter;
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