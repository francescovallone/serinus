/// The class Query is used to mark that a parameter is a query parameter
/// 
/// Example:
/// ``` dart
/// @Get('/users')
/// Future<Response> getUsers(@Query('name') String name) async {
/// // ...
/// }
/// ```
/// 
/// The [name] parameter is required and is used to define the name of the parameter
/// 
/// The [nullable] parameter is optional and is used to define if the parameter is nullable
/// 
/// If the parameter is not nullable and the value is null the application will throw a [StateError]
class Query{

  final String name;
  final bool nullable;

  const Query(this.name, { this.nullable = false });

}