import 'package:serinus/serinus.dart';

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