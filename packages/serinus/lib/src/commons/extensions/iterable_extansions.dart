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
  Iterable<T> flatten() => [
    for (var element in this) ...element
  ];
}

extension SegmentedPathMap on Iterable<String> {
  Iterable<({bool isLast, String value})> get pathMap {
    final segments = toList();
    return segments.asMap().entries.map((e) {
      return (isLast: e.key == segments.length - 1, value: e.value);
    });
  }
}