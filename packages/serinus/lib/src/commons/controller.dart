import 'dart:mirrors';

import 'package:meta/meta.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/utils/container_utils.dart';

/// SerinusController is an abstract class that is used to create a controller
/// every controller in the application must extend this class
/// 
/// Example:
/// ``` dart
/// class HomeController extends SerinusController{
/// // ...
/// }
/// ```
abstract class SerinusController{

  const SerinusController();

  @nonVirtual
  Controller get annotation => isController(reflect(this));
}