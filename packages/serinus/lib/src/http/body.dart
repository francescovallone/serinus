import 'dart:convert';
import 'dart:io';

import 'form_data.dart';

/// The class [Body] is used to create a body for the request.
class Body {
  /// If the content type is [multipart/form-data] or [x-www-form-urlencoded], the [formData] will be used.
  final FormData? formData;

  /// The content type of the body.
  final ContentType contentType;

  /// The content of the body if it is text.
  final String? text;

  /// The content of the body if it is binary.
  final List<int>? bytes;

  /// The content of the body if it is json.
  final JsonBody? json;

  /// The [Body] constructor is used to create a new instance of the [Body] class.
  Body(this.contentType, {this.formData, this.text, this.bytes, this.json});

  /// Factory constructor to create an empty body.
  factory Body.empty() => Body(ContentType.text);

  /// This method is used to change the body of the request.
  ///
  /// It will return a new instance of the [Body] class.
  Body change({
    FormData? formData,
    ContentType? contentType,
    String? text,
    List<int>? bytes,
    JsonBody? json,
  }) {
    if (formData != null) {
      return Body(contentType ?? this.contentType, formData: formData);
    } else if (text != null) {
      return Body(contentType ?? this.contentType, text: text);
    } else if (bytes != null) {
      return Body(contentType ?? this.contentType, bytes: bytes);
    } else if (json != null) {
      return Body(contentType ?? this.contentType, json: json);
    }
    return this;
  }

  /// This method is used to get the length of the body.
  int get length {
    if (json != null) {
      return json.toString().length;
    }
    return text?.length ?? bytes?.length ?? formData?.length ?? 0;
  }

  /// This method is used to get the content of the json body.
  dynamic get value {
    if (json != null) {
      return json!.value;
    }
    if (formData != null) {
      return formData!.fields;
    }
    return text ?? bytes;
  }

  @override
  String toString() {
    if (json != null) {
      return json!.toString();
    }
    if (formData != null) {
      return jsonEncode(formData!.fields);
    }
    return text ?? utf8.decoder.convert(bytes ?? []);
  }
}

/// The class [JsonBody] is used to create a json body for the request.
///
/// The [JsonBody] class is an abstract class that is used express both a single json object and a list of json objects.
abstract class JsonBody<T> {
  /// true if the body is a list of json objects.
  final bool multiple;

  /// The value of the body.
  final T value;

  /// The [JsonBody] constructor is used to create a new instance of the [JsonBody] class.
  JsonBody(this.value, {this.multiple = false});

  /// This method is used to create a new instance of the [JsonBody] class from a json object.
  factory JsonBody.fromJson(dynamic json) {
    if (json is List) {
      return JsonList(json) as JsonBody<T>;
    }
    return JsonBodyObject(json) as JsonBody<T>;
  }

  @override
  String toString() => jsonEncode(value);
}

/// The class [JsonBodyObject] is used to create a json object body for the request.
class JsonBodyObject extends JsonBody<Map<String, dynamic>> {
  /// The [JsonBodyObject] constructor is used to create a new instance of the [JsonObject] class.
  JsonBodyObject(super.value);
}

/// The class [JsonList] is used to create a json list body for the request.
///
/// The [JsonList] class is used to express a list of json objects.
/// Examples:
///
/// ```dart
/// final body = JsonList([
///  {'name': 'John Doe', 'age': 30},
/// {'name': 'Jane Doe', 'age': 25},
/// ]);
///
/// final body = JsonList(['1', '2', '3']);
///
/// final body = JsonList([1, 2, 3]);
///
/// final body = JsonList([true, false, true]);
/// ```
class JsonList extends JsonBody<List<dynamic>> {
  /// The [JsonList] constructor is used to create a new instance of the [JsonList] class.
  JsonList(super.value) : super(multiple: true);
}
