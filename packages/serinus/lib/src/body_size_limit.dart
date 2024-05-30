import 'enums/size_value.dart';
import 'http/body.dart';

/// Body size limit for request body
final class BodySizeLimit {

  /// Limit for json body size in bytes
  final int jsonLimit;
  /// Limit for form body size in bytes
  final int formLimit;
  /// Limit for text body size in bytes
  final int textLimit;
  /// Limit for bytes body size in bytes
  final int bytesLimit;

  /// Create a new body size limit
  const BodySizeLimit({
    this.jsonLimit = 1000000,
    this.formLimit = 10000000,
    this.textLimit = 1000000,
    this.bytesLimit = 1000000
  });

  /// Create a new body size limit
  factory BodySizeLimit.change({
    int? jsonLimit,
    int? formLimit,
    int? textLimit,
    int? bytesLimit,
    BodySizeValue size = BodySizeValue.mb,
  }) {
    if(jsonLimit == null && formLimit == null && textLimit == null && bytesLimit == null) {
      throw Exception('At least one limit must be provided');
    }
    if([
      if(jsonLimit != null) jsonLimit,
      if(formLimit != null) formLimit,
      if(textLimit != null) textLimit,
      if(bytesLimit != null) bytesLimit,
    ].any((element) => element < 0)) {
      throw Exception('Limit cannot be negative');
    }
    if(jsonLimit != null) {
      return BodySizeLimit(jsonLimit: size.value * jsonLimit);
    }
    if(formLimit != null) {
      return BodySizeLimit(formLimit: size.value * formLimit);
    }
    if(textLimit != null) {
      return BodySizeLimit(textLimit: size.value * textLimit);
    }
    if(bytesLimit != null) {
      return BodySizeLimit(bytesLimit: size.value * bytesLimit);
    }
    return BodySizeLimit();
  }

  /// Check if the body size is exceeded
  bool isExceeded(Body body) {
    if(body.json != null) {
      return body.length > jsonLimit;
    }
    if(body.text != null) {
      return body.length > textLimit;
    }
    if(body.bytes != null) {
      return body.length > bytesLimit;
    }
    if(body.formData != null) {
      return body.length > formLimit;
    }
    return false;
  }

}