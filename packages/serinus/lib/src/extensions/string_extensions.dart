import 'dart:convert';

extension JsonString on String {
  dynamic tryParse() {
    try {
      return jsonDecode(this);
    } catch (e) {
      return null;
    }
  }
}
