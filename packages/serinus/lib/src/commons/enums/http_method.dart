/// HTTP methods
/// 
/// This enum contains all the HTTP methods that can be used in a request
enum HttpMethod{
  get,
  post,
  delete,
  put,
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
  HttpMethod toHttpMethod(){
    switch(toLowerCase().trim()){
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