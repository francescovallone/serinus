import 'package:meta/meta.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus/src/utils/container_utils.dart';

/// The class SerinusModule is used to define a module
/// every module in the application must extend this class
/// 
/// Example:
/// ``` dart
/// class HomeModule extends SerinusModule{
/// // ...
/// }
/// ```
abstract class SerinusModule{

  const SerinusModule();

  /// The method configure is used to configure the module middleware
  /// that will be shared by all the imported modules
  configure(MiddlewareConsumer consumer){}

  @nonVirtual
  Module get annotation => getModule(this);
}