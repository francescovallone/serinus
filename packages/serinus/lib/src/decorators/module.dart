import 'package:serinus/serinus.dart';

/// The class Module is used to mark a class as a module
/// 
/// Example:
/// ``` dart
/// @Module(
///  imports: [OtherModule],
///   controllers: [UserController],
///   providers: [UserService],
///   exports: [UserService]
/// )
/// class AppModule extends SerinusModule{}
/// ```
/// 
/// The [imports] parameter is optional and is used to import other modules
/// 
/// The [controllers] parameter is optional and is used to define the controllers of the module
/// 
/// The [providers] parameter is optional and is used to define the providers of the module
/// 
/// The [exports] parameter is optional and is used to define the services exported of the module
class Module{

  final List<SerinusModule> imports;
  final List<Type> controllers;
  final List<Type> providers;
  final List<Type> exports;

  const Module({
    this.imports = const [],
    this.controllers = const [],
    this.providers = const [],
    this.exports = const []
  });

}