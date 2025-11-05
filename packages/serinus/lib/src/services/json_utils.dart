import '../containers/models_provider.dart';
import '../extensions/object_extensions.dart';
import '../mixins/mixins.dart';

/// Utility function to parse a json to a response.
dynamic parseJsonToResponse(dynamic data, ModelProvider? provider) {
  if (data == null) {
    return null;
  }

  if ((data as Object).runtimeType.isPrimitive()) {
    return data;
  }

  if (provider?.toJsonModels.containsKey(data.runtimeType.toString()) ??
      false) {
    return provider?.to(data);
  }

  if (data is Map) {
    return data.map((key, value) {
      if (value is JsonObject) {
        return MapEntry(key, parseJsonToResponse(value.toJson(), provider));
      } else if (value is Iterable<JsonObject>) {
        return MapEntry(
          key,
          value.map((e) => parseJsonToResponse(e.toJson(), provider)).toList(),
        );
      } else if (provider?.toJsonModels.containsKey(
            value.runtimeType.toString(),
          ) ??
          false) {
        return MapEntry(key, provider?.to(value));
      } else if (value is DateTime || value is DateTime?) {
        return MapEntry(key, value?.toIso8601String());
      }
      if (value is Map) {
        return MapEntry(key, parseJsonToResponse(value, provider));
      }
      return MapEntry(key, value);
    });
  }

  if (data is Iterable<Map> || data is Iterable<Object>) {
    return (data as Iterable<Object>)
        .map((e) {
          if (e is JsonObject) {
            return parseJsonToResponse(e.toJson(), provider);
          } else if (provider?.toJsonModels.containsKey(
                e.runtimeType.toString(),
              ) ??
              false) {
            return provider?.to(e);
          } else if (e is DateTime || e is DateTime?) {
            return (e as DateTime?)?.toIso8601String();
          } else if (e is Map) {
            return parseJsonToResponse(e, provider);
          } else {
            return e;
          }
        })
        .toList(growable: false);
  }

  if (data is JsonObject) {
    return parseJsonToResponse(data.toJson(), provider);
  }

  if (data is Iterable<JsonObject>) {
    return data
        .map((e) => parseJsonToResponse(e.toJson(), provider))
        .toList(growable: false);
  }

  throw FormatException('The data must be a json parsable type');
}
