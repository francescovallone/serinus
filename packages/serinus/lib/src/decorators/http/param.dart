/// The class Param is used to mark that a parameter is a path parameter
/// 
/// Example:
/// ``` dart
/// @Get('/users/:id')
/// Future<Response> getUser(@Param('id') String id) async {
/// // ...
/// }
/// ```
/// 
/// The [name] parameter is required and is used to define the name of the parameter
/// 
/// The [nullable] parameter is optional and is used to define if the parameter is nullable
/// 
/// If the parameter is not nullable and the value is null the application will throw a [StateError]
class Param{

  final String name;
  final bool nullable;

  const Param(this.name, { this.nullable = false });
}