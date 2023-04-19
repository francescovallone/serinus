/// HTTP methods
/// 
/// This enum contains all the HTTP methods that can be used in a request
enum Method{
  get,
  post,
  delete,
  put,
  options,
  head,
  patch;

  /// Returns the string representation of the method
  @override
  String toString() {
    return this.name.toUpperCase();
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
  Method toMethod(){
    switch(this.toLowerCase()){
      case 'post':
        return Method.post;
      case 'put':
        return Method.put;
      case 'delete':
        return Method.delete;
      case 'options':
        return Method.options;
      case 'head':
        return Method.head;
      case 'patch':
        return Method.patch;
      default:
        return Method.get;
    }
  }
}