import 'dart:io';

import 'serinus_exception.dart';

/// The class InternalServerError is used to throw a internal server error exception
/// 
/// Example:
/// ``` dart
/// throw InternalServerError();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// 
class InternalServerError extends SerinusException{
  const InternalServerError({String message = "Internal server error!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.internalServerError
  );
}