import 'dart:io';

/// The class [Session] exposes the methods to interact with the session of the request.
/// 
/// [Session] is a wrapper around the [HttpSession] class.
class Session {

  /// The original [HttpSession] object.
  final HttpSession _original;

  Session(this._original);

  /// This method is used to get a value from the session.
  /// 
  /// Returns a value from the session. (dynamic, it can be null)
  dynamic get(String key) {
    return _original[key];
  }

  /// This method is used to put a value in the session.
  /// 
  /// Puts a value in the session.
  void put(String key, dynamic value) {
    _original[key] = value;
  }

  /// This method is used to remove a value from the session.
  void remove(String key) {
    _original.remove(key);
  }

  /// The id of the session.
  String get id => _original.id;

  /// It returns true if the session is new.
  bool get isNew => _original.isNew;

  /// This method is used to destroy the session.
  void destroy() {
    _original.destroy();
  }
}
