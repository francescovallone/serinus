class ResponseDecoder{

  static Map<String, dynamic> convertMap(Map<dynamic, dynamic> map) {
    map.forEach((key, value) {
      if (value is Map) {
        print(value);
        value = convertMap(value);
      }
    });
    return Map<String, dynamic>.fromEntries(map.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)));
  }

  static String formatContentLength(int contentLength){
    if(contentLength >= 1024 * 1024){
      return "$contentLength MB";
    }else if(contentLength >= 1024){
      return "$contentLength KB";
    }
    return "$contentLength B";
  }

}