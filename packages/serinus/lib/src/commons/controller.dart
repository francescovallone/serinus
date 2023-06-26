import 'dart:mirrors';

import 'package:meta/meta.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/commons/decorators/http/route.dart';
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

  @nonVirtual
  String get path => annotation.path;

  @nonVirtual
  Map<Symbol, MethodMirror> get routes {
    Map<Symbol, MethodMirror> map = Map<Symbol, MethodMirror>.from(reflect(this).type.instanceMembers);
    map.removeWhere((key, value) => value.metadata.indexWhere((element) => element.reflectee is Route) == -1);
    return map; 
  }
}