/// The class Body is used to mark that a parameter is a body parameter
/// 
/// Example:
/// ``` dart
/// @Post('/users')
/// Future<Response> createUser(@Body() User user) async {
///  // ...
/// }
/// ```
/// 
/// The body parameter can be a class that implements [BodyParsable]
/// but it can also be a simple type like [String], [int], [double], [bool]

class Body {
  
  const Body();
  
}