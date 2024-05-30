/// This extension is used to parse a [Map] to a [String] and convert a [Map] to a [Map<String, dynamic>]
extension JsonParsing on dynamic {

  /// This method is used to parse a [Map] to a [String].
  String parseJson() {
    try {
      return jsonEncode(this);
    } catch (e) {
      throw StateError('Error while parsing json');
    }
  }

  /// This method is used to convert a [Map] to a [Map<String, dynamic>]
  Map<String, dynamic> convertMap() {
    Map<String, dynamic> convertedMap = {};
    for (var key in this.keys) {
      if (this[key] is Map) {
        convertedMap[key.toString()] = this[key].convertMap();
      } else {
        convertedMap[key.toString()] = this[key];
      }
    }
    return Map<String, dynamic>.from(convertedMap);
  }
}
