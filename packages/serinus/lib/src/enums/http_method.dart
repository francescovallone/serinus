import 'package:spanner/spanner.dart';

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
  options,

  /// The ALL method matches all HTTP methods.
  all;

  /// Returns the string representation of the method
  @override
  String toString() {
    return name.toUpperCase();
  }

  /// Parses a string to return the corresponding [HttpMethod]
  static HttpMethod parse(String method) {
    switch (method.toUpperCase().trim()) {
      case 'POST':
        return HttpMethod.post;
      case 'PUT':
        return HttpMethod.put;
      case 'DELETE':
        return HttpMethod.delete;
      case 'PATCH':
        return HttpMethod.patch;
      case 'HEAD':
        return HttpMethod.head;
      case 'OPTIONS':
        return HttpMethod.options;
      case 'ALL':
        return HttpMethod.all;
      default:
        return HttpMethod.get;
    }
  }

  /// Converts a [HttpMethod] to a [HTTPMethod]
  static HTTPMethod toSpanner(HttpMethod method) {
    return switch (method) {
      HttpMethod.get => HTTPMethod.GET,
      HttpMethod.post => HTTPMethod.POST,
      HttpMethod.put => HTTPMethod.PUT,
      HttpMethod.delete => HTTPMethod.DELETE,
      HttpMethod.patch => HTTPMethod.PATCH,
      HttpMethod.head => HTTPMethod.HEAD,
      HttpMethod.options => HTTPMethod.OPTIONS,
      HttpMethod.all => HTTPMethod.ALL,
    };
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
