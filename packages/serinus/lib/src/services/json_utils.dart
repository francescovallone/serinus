import '../mixins/mixins.dart';

/// Utility function to parse a json to a response.
dynamic parseJsonToResponse(dynamic data) {
  Object responseData;
  if (data is Map) {
    responseData = data.map((key, value) {
      if (value is JsonObject) {
        return MapEntry(key, parseJsonToResponse(value.toJson()));
      } else if (value is List<JsonObject>) {
        return MapEntry(
            key, value.map((e) => parseJsonToResponse(e.toJson())).toList());
      }
      return MapEntry(key, value);
    });
  } else if (data is List<Map<String, dynamic>> || data is List<Object>) {
    final listObject = data as List<Object>;
    responseData =
        listObject.map((e) => parseJsonToResponse(e)).toList(growable: false);
  } else if (data is JsonObject) {
    responseData = parseJsonToResponse(data.toJson());
  } else if (data is List<JsonObject>) {
    responseData = data
        .map((e) => parseJsonToResponse(e.toJson()))
        .toList(growable: false);
  } else {
    throw FormatException('The data must be a json parsable type');
  }
  return responseData;
}
