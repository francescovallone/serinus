class Module{

  final List<dynamic> imports;
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