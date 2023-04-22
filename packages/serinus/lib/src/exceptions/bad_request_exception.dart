import 'dart:io';

import 'package:serinus/src/exceptions/serinus_exception.dart';

/// The class BadRequestException is used to throw a bad request exception
/// 
/// Example:
/// ``` dart
/// throw BadRequestException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 400
class BadRequestException extends SerinusException{
  const BadRequestException({String message = "Bad Request!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.badRequest
  );
}