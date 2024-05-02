extension FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}

extension Flatten<T> on Iterable<Iterable<T>> {
  Iterable<T> flatten() => [for (var element in this) ...element];
}

extension SegmentedPathMap on Iterable<String> {
  Iterable<({bool isLast, String value})> get pathMap {
    final segments = toList();
    return segments.asMap().entries.map((e) {
      return (isLast: e.key == segments.length - 1, value: e.value);
    });
  }
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
