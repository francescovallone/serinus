import 'package:serinus/old/serinus.dart';

sealed class Route{

  final String path;
  final Method method;
  final int statusCode;

  const Route(this.path, {this.method = Method.get, this.statusCode = 200});

  Map<int, dynamic> get params => Map<int, dynamic>.fromEntries(
    path.split('/').asMap().map((idx, e) {
      if(e.startsWith(':')){
        return MapEntry(idx, e.substring(1));
      }
      return MapEntry(idx, null);
    }).entries.where((element) => element.value != null)
  );

}

class Get extends Route{
  const Get({String path = '/', super.statusCode}) : super(path);
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
  const Post({String path = '/', int statusCode = 201}) : super(path, method: Method.post, statusCode: statusCode);
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
  const Put({String path = '/', super.statusCode}) : super(path, method: Method.put);
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
  const Delete({String path = '/', super.statusCode}) : super(path, method: Method.delete);
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
  const Patch({String path = '/', super.statusCode}) : super(path, method: Method.patch);
}
