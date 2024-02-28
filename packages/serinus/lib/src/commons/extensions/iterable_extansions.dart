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