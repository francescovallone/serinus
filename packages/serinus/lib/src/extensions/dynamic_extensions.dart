
extension JsonParsing on dynamic {
  String parseJson() {
    try {
      return jsonEncode(this);
    } catch (e) {
      throw StateError('Error while parsing json');
    }
  }

  Map<String, dynamic> convertMap() {
    Map<String, dynamic> convertedMap = {};
    for (var key in this.keys) {
      if (this[key] is Map) {
        convertedMap[key.toString()] = this[key].convertMap();
        // }else if(this[key] is UploadedFile){
        //   convertedMap[key.toString()] = this[key].toString();
        // }else if(this[key] is FormData){
        //   convertedMap[key.toString()] = this[key].convertMap();
      } else {
        convertedMap[key.toString()] = this[key];
      }
    }
    return Map<String, dynamic>.from(convertedMap);
  }
}
