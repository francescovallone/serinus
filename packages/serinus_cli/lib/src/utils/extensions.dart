import 'package:code_builder/code_builder.dart';

extension NullIfEmpty on String? {
  String? get nullIfEmpty => (this?.isEmpty ?? true) ? null : this;
}

extension SingletonBuilder on ClassBuilder {

  void buildSingleton(String className) {
    fields.add(
      Field((f) {
        f
          ..name = '_instance'
          ..static = true
          ..modifier = FieldModifier.final$
          ..assignment = Code('$className._()');
      }),
    );
    constructors.addAll([
      Constructor((c) {
        c.name = '_';
      }),
      Constructor((c) {
        c
          ..body = const Code('return _instance;')
          ..factory = true;
      }),
    ]);
  }

}