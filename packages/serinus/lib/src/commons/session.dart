import 'dart:io';

class Session {
  final HttpSession _original;

  Session(this._original);

  dynamic get(String key) {
    return _original[key];
  }

  void put(String key, dynamic value) {
    _original[key] = value;
  }

  void remove(String key) {
    _original.remove(key);
  }

  String get id => _original.id;

  bool get isNew => _original.isNew;

  void destroy() {
    _original.destroy();
  }
}
