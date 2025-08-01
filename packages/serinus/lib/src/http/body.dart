import 'dart:convert';
import 'dart:io';

import 'form_data.dart';

/// The class [Body] is used to create a body for the request.
abstract class Body<T> {
  
  /// The content type of the body.
  final ContentType contentType;

  /// The [Body] constructor is used to create a new instance of the [Body] class.
  const Body(this.contentType, this.value);

  /// Factory constructor to create an empty body.
  factory Body.empty() => EmptyBody() as Body<T>;

  /// This method is used to get the length of the body.
  int get length;

  /// This method is used to get the content of the json body.
  final T value;

  @override
  String toString();
}

/// The class [JsonBody] is used to create a json body for the request.
///
/// The [JsonBody] class is an abstract class that is used express both a single json object and a list of json objects.
abstract class JsonBody<T> extends Body<T>{
  /// true if the body is a list of json objects.
  final bool multiple;

  /// The [JsonBody] constructor is used to create a new instance of the [JsonBody] class.
  JsonBody(T value, {this.multiple = false}) : super(ContentType.json, value);

  /// This method is used to create a new instance of the [JsonBody] class from a json object.
  factory JsonBody.fromJson(dynamic json) {
    if (json is List) {
      return JsonList(json) as JsonBody<T>;
    }
    return JsonBodyObject(json) as JsonBody<T>;
  }

  @override
  String toString() => jsonEncode(value);
  
  @override
  int get length => toString().length;

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
class JsonList<T> extends JsonBody<List<T>> {
  /// The [JsonList] constructor is used to create a new instance of the [JsonList] class.
  JsonList(super.value) : super(multiple: true);

}

class StringBody extends Body<String> {
  /// The [StringBody] constructor is used to create a new instance of the [StringBody] class.
  StringBody(String value) : super(ContentType.text, value);

  @override
  int get length => value.length;

  @override
  String toString() => value;
  
}

class FormDataBody extends Body<FormData> {
  /// The [FormDataBody] constructor is used to create a new instance of the [FormDataBody] class.
  FormDataBody(FormData value) : super(value.contentType, value);

  @override
  int get length => value.length;

  @override
  String toString() => jsonEncode(value.values);
}

class EmptyBody extends Body<String> {
  /// The [EmptyBody] constructor is used to create a new instance of the [EmptyBody] class.
  EmptyBody() : super(ContentType.text, '');

  @override
  int get length => 0;

  @override
  String toString() => '';
}

class RawBody extends Body<List<int>> {
  /// The [RawBody] constructor is used to create a new instance of the [RawBody] class.
  RawBody(List<int> value) : super(ContentType.binary, value);

  @override
  int get length => value.length;

  @override
  String toString() => utf8.decode(value);
}

class CustomBody<T> extends Body<T> {
  /// The [CustomBody] constructor is used to create a new instance of the [CustomBody] class.
  CustomBody(ContentType contentType, T value) : super(contentType, value);

  @override
  int get length => value.toString().length;

  @override
  String toString() => value.toString();
}