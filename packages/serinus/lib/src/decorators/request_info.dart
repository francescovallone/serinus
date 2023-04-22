/// The class RequestInfo is used to mark that route will access the request object
/// 
/// Example:
/// ``` dart
/// @Get('/users')
/// Future<Response> getUsers(@RequestInfo() Request request) async {
/// // ...
/// }
/// ```
/// 
class RequestInfo{

  const RequestInfo();

}