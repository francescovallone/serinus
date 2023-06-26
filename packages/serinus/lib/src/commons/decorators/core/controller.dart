import 'package:serinus/src/commons/decorators/core/injectable.dart';

/// The class Controller is used to mark a class as a controller
/// 
/// Example:
/// ``` dart
/// @Controller('/users')
/// class UserController{
/// // ...
/// }
/// ```
/// 
/// The [path] parameter is optional and is used to define the path of the controller.
/// If there are two controllers with the same path the application will throw a [StateError]

class Controller extends Injectable{

  final String path;

  const Controller([this.path = ""]);

  

}