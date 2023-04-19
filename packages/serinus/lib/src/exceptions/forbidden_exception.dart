import 'dart:io';

import 'serinus_exception.dart';

/// The class ForbiddenException is used to throw a forbidden exception
/// 
/// Example:
/// ``` dart
/// throw ForbiddenException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 403
class ForbiddenException extends SerinusException{
  const ForbiddenException({String message = "Forbidden!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.forbidden
  );
}