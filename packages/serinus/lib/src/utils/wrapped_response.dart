import 'dart:convert';
import 'dart:typed_data';

import '../extensions/object_extensions.dart';

/// The [WrappedResponse] class is used to wrap the response data.
class WrappedResponse {

  /// The wrapped data.
  Object? data;

  /// Create a new [WrappedResponse] instance with the given data.
  WrappedResponse(this.data);

  /// Convert the data to bytes.
  Uint8List toBytes() {
    if(data == null) {
      return Uint8List(0);
    }
    if (data is! Uint8List) {
      if (data.runtimeType.isPrimitive()) {
        return data?.toBytes() ?? Uint8List(0);
      } else {
        return jsonEncode(data).toBytes();
      }
    } else {
      return data as Uint8List;
    }
  }

}