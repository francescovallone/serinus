/// The class Req is used to mark that route will access the request object
/// 
/// Example:
/// ``` dart
/// @Get('/users')
/// Future<Response> getUsers(@Req() Request request) async {
/// // ...
/// }
/// ```
/// 
class Req{

  const Req();

}