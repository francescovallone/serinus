import '../extensions/object_extensions.dart';
import '../mixins/mixins.dart';

/// Utility function to parse a json to a response.
dynamic parseJsonToResponse(dynamic data) {
  if (data == null) {
    return null;
  }
  if ((data as Object).isPrimitive()) {
    return data;
  }

  if (data is Map) {
    return data.map((key, value) {
      if (value is JsonObject) {
        return MapEntry(key, parseJsonToResponse(value.toJson()));
      } else if (value is Iterable<JsonObject>) {
        return MapEntry(
            key, value.map((e) => parseJsonToResponse(e.toJson())).toList());
      } else if (value is DateTime || value is DateTime?) {
        return MapEntry(key, value?.toIso8601String());
      }
      if (value is Map) {
        return MapEntry(key, parseJsonToResponse(value));
      }
      return MapEntry(key, value);
    });
  }

  if (data is Iterable<Map> || data is Iterable<Object>) {
    return (data as Iterable<Object>)
        .map((e) => parseJsonToResponse(e))
        .toList(growable: false);
  }

  if (data is JsonObject) {
    return parseJsonToResponse(data.toJson());
  }

  if (data is Iterable<JsonObject>) {
    return data
        .map((e) => parseJsonToResponse(e.toJson()))
        .toList(growable: false);
  }

  throw FormatException('The data must be a json parsable type');
}
