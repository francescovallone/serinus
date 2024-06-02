/// This file contains the extensions for the Iterable class
extension Flatten<T> on Iterable<Iterable<T>> {
  /// This method is used to flatten a list of lists
  Iterable<T> flatten() => [for (var element in this) ...element];
}

/// This extension is used to add an element to the list if it is not already present
extension AddIfAbsent<T> on Iterable<T> {
  /// This method is used to add an element to the list if it is not already present
  Iterable<T> addIfAbsent(T element) {
    final elementsType = map((e) => e.runtimeType);
    if (!elementsType.contains(element.runtimeType)) {
      return [...this, element];
    }
    return this;
  }

  /// This method is used to add a list of elements to the list if they are not already present
  Iterable<T> addAllIfAbsent(Iterable<T> elements) {
    return elements.fold(this, (acc, element) => acc.addIfAbsent(element));
  }
}
