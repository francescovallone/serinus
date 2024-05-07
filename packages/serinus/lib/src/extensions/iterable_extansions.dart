extension Flatten<T> on Iterable<Iterable<T>> {
  Iterable<T> flatten() => [for (var element in this) ...element];
}

extension AddIfAbsent<T> on Iterable<T> {
  Iterable<T> addIfAbsent(T element) {
    final elementsType = map((e) => e.runtimeType);
    if (!elementsType.contains(element.runtimeType)) {
      return [...this, element];
    }
    throw ArgumentError(
        'Element ${element.runtimeType} already exists in the list');
  }

  Iterable<T> addAllIfAbsent(Iterable<T> elements) {
    return elements.fold(this, (acc, element) => acc.addIfAbsent(element));
  }
}
