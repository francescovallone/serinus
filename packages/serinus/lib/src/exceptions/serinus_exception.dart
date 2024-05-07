import 'dart:convert';
import 'dart:io';

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
class SerinusException implements HttpException {
  @override
  final String message;
  @override
  final Uri? uri;

  final int statusCode;

  const SerinusException(
      {required this.message, required this.statusCode, this.uri});

  @override
  String toString() {
    return jsonEncode({
      'message': message,
      'statusCode': statusCode,
      'uri': uri != null ? uri!.path : 'No Uri'
    });
  }
}
