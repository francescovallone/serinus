class ResponseDecoder{

  Map<String, dynamic> convertMap(Map<dynamic, dynamic> map) {
    map.forEach((key, value) {
      if (value is Map) {
        print(value);
        value = convertMap(value);
      }
    });
    return Map<String, dynamic>.fromEntries(map.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)));
  }

}