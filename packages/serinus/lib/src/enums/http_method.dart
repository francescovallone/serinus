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
  patch,

  /// The HEAD method asks for a response identical to that of a GET request, but without the response body.
  head,

  /// The OPTIONS method is used to describe the communication options for the target resource.
  options;

  /// Returns the string representation of the method
  @override
  String toString() {
    return name.toUpperCase();
  }

  /// Parses a string to return the corresponding [HttpMethod]
  static HttpMethod parse(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
      case 'post':
        return HttpMethod.post;
      case 'PUT':
      case 'put':
        return HttpMethod.put;
      case 'DELETE':
      case 'delete':
        return HttpMethod.delete;
      case 'PATCH':
      case 'patch':
        return HttpMethod.patch;
      case 'HEAD':
      case 'head':
        return HttpMethod.head;
      case 'OPTIONS':
      case 'options':
        return HttpMethod.options;
      default:
        return HttpMethod.get;
    }
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
      case 'head':
        return HttpMethod.head;
      case 'options':
        return HttpMethod.options;
      default:
        return HttpMethod.get;
    }
  }
}
