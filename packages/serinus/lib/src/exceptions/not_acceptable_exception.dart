import 'dart:io';

import 'serinus_exception.dart';

/// The class NotAcceptableException is used to throw a not acceptable exception
/// 
/// Example:
/// ``` dart
/// throw NotAcceptableException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 406
class NotAcceptableException extends SerinusException{
  const NotAcceptableException({String message = "Not acceptable!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.notAcceptable
  );
}