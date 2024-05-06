import 'dart:io';

extension ContentTypeExtensions on ContentType {
  bool isUrlEncoded() => subType == 'x-www-form-urlencoded';
  bool isMultipart() => mimeType == 'multipart/form-data';
}
