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
    final elementsType = map((e) => e.runtimeType);
    final currentElements = [...this];
    for (final element in elements) {
      if (!elementsType.contains(element.runtimeType)) {
        currentElements.add(element);
      }
    }
    return currentElements;
  }
}

/// This extension is used to split a list into two lists based on the type
/// of the elements
///
/// Example:
/// ```dart
/// final list = [1, '2', 3, '4'];
/// final split = list.splitBy<String>();
///
/// print(split.notOfType); // [1, 3]
/// print(split.ofType); // ['2', '4']
///
/// ```
extension SplitTypes<T> on Iterable<T> {
  /// This method is used to split a list into two lists based on the type
  ({Iterable<T> notOfType, Iterable<R> ofType}) splitBy<R>() {
    final notOfType = <T>[];
    final ofType = <R>[];
    for (final element in this) {
      if (element is R) {
        ofType.add(element as R);
      } else {
        notOfType.add(element);
      }
    }
    return (notOfType: notOfType, ofType: ofType);
  }
}
