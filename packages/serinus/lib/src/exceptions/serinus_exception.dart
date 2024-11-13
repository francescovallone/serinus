import 'dart:io';
import 'dart:typed_data';

import '../extensions/string_extensions.dart';
import '../mixins/mixins.dart';

/// The class SerinusException is used as superclass for all exceptions
/// defined in Serinus
///
/// Example:
/// ``` dart
/// class MyException extends SerinusException{
///  const MyException({String message = "My Exception!", Uri? uri}) : super(
///    message: message,
///   uri: uri,
///  statusCode: 500
/// );
/// }
/// ```
///
/// The [message] parameter is optional and is used to define the message of the exception
///
/// The [uri] parameter is optional and is used to define the uri of the exception
class SerinusException with JsonObject implements HttpException {
  @override
  final String message;
  @override
  final Uri? uri;

  /// The [statusCode] parameter is used to define the status code of the exception
  final int statusCode;

  /// The [SerinusException] constructor is used to create a new instance of the [SerinusException] class.
  const SerinusException(
      {required this.message, required this.statusCode, this.uri});

  @override
  Map<String, dynamic> toJson() {
    return {
      'message': Uint8List.fromList(message.codeUnits).tryParse() ?? message,
      'statusCode': statusCode,
      'uri': uri != null ? uri!.path : 'No Uri'
    };
  }
}
