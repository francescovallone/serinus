/// The [Hook] class is used to create hooks that can be used to execute code before and after the request is handled
abstract class Hook implements Hookable {
  /// The [Hook] constructor is used to create a [Hook] object.
  const Hook();
}

/// The [Hookable] class is used to create a hookable object.
abstract class Hookable {}
