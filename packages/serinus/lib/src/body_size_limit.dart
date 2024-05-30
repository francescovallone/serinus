import 'enums/size_value.dart';
import 'http/body.dart';

/// Body size limit for request body
final class BodySizeLimit {
  /// Limit for json body size in bytes
  final int json;

  /// Limit for form body size in bytes
  final int form;

  /// Limit for text body size in bytes
  final int text;

  /// Limit for bytes body size in bytes
  final int bytes;

  /// Create a new body size limit
  const BodySizeLimit(
      {this.json = 1000000,
      this.form = 10000000,
      this.text = 1000000,
      this.bytes = 1000000});

  /// Create a new body size limit
  factory BodySizeLimit.change({
    int? json,
    int? form,
    int? text,
    int? bytes,
    BodySizeValue size = BodySizeValue.mb,
  }) {
    if ([
      if (json != null) json,
      if (form != null) form,
      if (text != null) text,
      if (bytes != null) bytes,
    ].any((element) => element < 0)) {
      throw Exception('Limit cannot be negative');
    }
    if (json != null) {
      return BodySizeLimit(json: size.value * json);
    }
    if (form != null) {
      return BodySizeLimit(form: size.value * form);
    }
    if (text != null) {
      return BodySizeLimit(text: size.value * text);
    }
    if (bytes != null) {
      return BodySizeLimit(bytes: size.value * bytes);
    }
    return BodySizeLimit();
  }

  /// Check if the body size is exceeded
  bool isExceeded(Body body) {
    if (body.json != null) {
      return body.length > json;
    }
    if (body.text != null) {
      return body.length > text;
    }
    if (body.bytes != null) {
      return body.length > bytes;
    }
    if (body.formData != null) {
      return body.length > form;
    }
    return false;
  }
}
