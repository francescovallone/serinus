import '../extensions/object_extensions.dart';
import '../mixins/mixins.dart';

/// Utility function to parse a json to a response.
dynamic parseJsonToResponse(dynamic data) {
  if ((data as Object).isPrimitive()) {
    return data;
  }

  if (data is Map) {
    return data.map((key, value) {
      if (value is JsonObject) {
        return MapEntry(key, parseJsonToResponse(value.toJson()));
      } else if (value is List<JsonObject>) {
        return MapEntry(
            key, value.map((e) => parseJsonToResponse(e.toJson())).toList());
      }
      return MapEntry(key, value);
    });
  }

  if (data is List<Map> || data is List<Object>) {
    return (data as List<Object>)
        .map((e) => parseJsonToResponse(e))
        .toList(growable: false);
  }

  if (data is JsonObject) {
    return parseJsonToResponse(data.toJson());
  }

  if (data is List<JsonObject>) {
    return data
        .map((e) => parseJsonToResponse(e.toJson()))
        .toList(growable: false);
  }

  throw FormatException('The data must be a json parsable type');
}
