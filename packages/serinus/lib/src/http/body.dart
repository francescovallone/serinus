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
  final Map<String, dynamic>? json;

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
    Map<String, dynamic>? json,
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
      return jsonEncode(json).length;
    }
    return text?.length ?? bytes?.length ?? formData?.length ?? 0;
  }

  /// This method is used to get the content of the json body.
  dynamic operator [](String key) => json?[key];

  /// This method is used to set the content of the json body.
  bool containsKey(String key) => json?.containsKey(key) ?? false;

  /// This method is used to get the content of the json body.
  dynamic get value {
    if (json != null) {
      return json;
    }
    if (formData != null) {
      return formData!.fields;
    }
    return text ?? bytes;
  }

  @override
  String toString() {
    if (json != null) {
      return jsonEncode(json);
    }
    if (formData != null) {
      return jsonEncode(formData!.fields);
    }
    return text ?? utf8.decoder.convert(bytes ?? []);
  }
}
