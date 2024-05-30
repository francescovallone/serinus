/// HTTP methods
///
/// This enum contains all the HTTP methods that can be used in a request
enum HttpMethod {
  /// The GET method requests a representation of the specified resource.
  get,
  /// The POST method is used to submit an entity to the specified resource, often causing a change in state or side effects on the server.
  post,
  /// The DELETE method deletes the specified resource.
  delete,
  /// The PUT method replaces all current representations of the target resource with the request payload.
  put,
  /// The PATCH method is used to apply partial modifications to a resource.
  patch;

  /// Returns the string representation of the method
  @override
  String toString() {
    return name.toUpperCase();
  }
}

/// Extension method to convert a string to a [Method]
///
/// This extension method can be used to convert a string to a [Method]
///
/// Example:
///
/// ``` dart
/// Method method = 'post'.toMethod();
/// ```
extension StringMethod on String {
  /// This method is used to convert a string to a [Method]
  HttpMethod toHttpMethod() {
    switch (toLowerCase().trim()) {
      case 'post':
        return HttpMethod.post;
      case 'put':
        return HttpMethod.put;
      case 'delete':
        return HttpMethod.delete;
      case 'patch':
        return HttpMethod.patch;
      default:
        return HttpMethod.get;
    }
  }
}
