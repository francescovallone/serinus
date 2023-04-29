import 'package:serinus/src/decorators/http/route.dart';
import 'package:serinus/src/enums/method.dart';

/// The class Get is used to mark a method as a route with GET method
/// 
/// Example:
/// ``` dart
/// @Get('/users')
/// Future<Response> getUsers() async {
/// // ...
/// }
/// ```
/// 
/// The [path] parameter is required and is used to define the path of the route
/// 
/// The [statusCode] parameter is optional and is used to define the status code of the response
/// 
/// The default status code is 200
class Get extends Route{
  const Get({String? path, super.statusCode}) : super(path ?? '/');
}

/// The class Post is used to mark a method as a route with POST method
/// 
/// Example:
/// ``` dart
/// @Post('/users')
/// Future<Response> createUser(@Body() User user) async {
/// // ...
/// }
/// ```
/// 
/// The [path] parameter is required and is used to define the path of the route
/// 
/// The [statusCode] parameter is optional and is used to define the status code of the response
/// 
/// The default status code is 201
class Post extends Route {
  const Post({String? path, int? statusCode}) : super(path ?? '/', method: Method.post, statusCode: statusCode ?? 201);
}

/// The class Put is used to mark a method as a route with PUT method
/// 
/// Example:
/// ``` dart
/// @Put('/users/:id')
/// Future<Response> updateUser(
///   @Param('id') String userId, 
///   @Body() Map<String, dynamic> body
/// ) async {
/// // ...
/// }
/// ```
/// 
/// The [path] parameter is required and is used to define the path of the route
/// 
/// The [statusCode] parameter is optional and is used to define the status code of the response
/// 
/// The default status code is 200
class Put extends Route{
  const Put({String? path, int? statusCode}) : super(path ?? '/', method: Method.put, statusCode: statusCode ?? 200);
}

/// The class Delete is used to mark a method as a route with DELETE method
/// 
/// Example:
/// ``` dart
/// @Delete('/users/:id')
/// Future<Response> deleteUser(@Param('id') String userId) async {
/// // ...
/// }
/// ```
/// 
/// The [path] parameter is required and is used to define the path of the route
/// 
/// The [statusCode] parameter is optional and is used to define the status code of the response
/// 
/// The default status code is 200
class Delete extends Route{
  const Delete({String? path, int? statusCode}) : super(path ?? '/', method: Method.delete, statusCode: statusCode ?? 200);
}

/// The class Patch is used to mark a method as a route with PATCH method
/// 
/// Example:
/// ``` dart
/// @Patch('/users/:id')
/// Future<Response> updateUser(
///   @Param('id') String userId,
///   @Body() Map<String, dynamic> body
/// ) async {
/// // ...
/// }
/// ```
/// 
/// The [path] parameter is required and is used to define the path of the route
/// 
/// The [statusCode] parameter is optional and is used to define the status code of the response
/// 
/// The default status code is 200
class Patch extends Route{
  const Patch({String? path, int? statusCode}) : super(path ?? '/', method: Method.patch, statusCode: statusCode ?? 200);
}

/// The class Head is used to mark a method as a route with HEAD method
/// 
/// Example:
/// ``` dart
/// @Head('/users/:id')
/// Future<Response> getUser(@Param('id') String userId) async {
/// // ...
/// }
/// ```
/// 
/// The [path] parameter is required and is used to define the path of the route
/// 
/// The [statusCode] parameter is optional and is used to define the status code of the response
/// 
/// The default status code is 200
class Head extends Route{
  const Head({String? path, int? statusCode}) : super(path ?? '/', method: Method.head, statusCode: statusCode ?? 200);
}

/// The class Options is used to mark a method as a route with OPTIONS method
/// 
/// Example:
/// ``` dart
/// @Options('/users/:id')
/// Future<Response> getUser(@Param('id') String userId) async {
/// // ...
/// }
/// ```
/// 
/// The [path] parameter is required and is used to define the path of the route
/// 
/// The [statusCode] parameter is optional and is used to define the status code of the response
/// 
/// The default status code is 200
class Options extends Route{
  const Options({String? path, int? statusCode}) : super(path ?? '/', method: Method.options, statusCode: statusCode ?? 200);
}
