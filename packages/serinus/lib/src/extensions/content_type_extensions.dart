import 'dart:io';

/// The extension [ContentTypeExtensions] is used to add functionalities to the [ContentType] class.
extension ContentTypeExtensions on ContentType {
  /// This method checks if the subtype is x-www-form-urlencoded.
  bool get isUrlEncoded => subType == 'x-www-form-urlencoded';

  /// This method checks if the it is a MultiPart request.
  bool get isMultipart => mimeType == 'multipart/form-data';

  /// This method checks if the subtype is json.
  bool get isJson =>
      mimeType == 'application/json' ||
      mimeType == 'text/json' ||
      subType.endsWith('+json');
}
