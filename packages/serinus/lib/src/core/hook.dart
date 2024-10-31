/// The [Hook] class is used to create hooks that can be used to execute code before and after the request is handled
abstract class Hook implements Hookable {
  /// The [Hook] constructor is used to create a [Hook] object.
  const Hook();

  /// The Hook can expose a service that will be used by the application without the need to create a new module.
  /// 
  /// The service can be accessed by the [RequestContext] object and they are treated as global services.
  Object? get service => null;
}

/// The [Hookable] class is used to create a hookable object.
abstract class Hookable {}
