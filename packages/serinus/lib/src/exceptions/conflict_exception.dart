import 'dart:io';

import 'serinus_exception.dart';

/// The class ConflictException is used to throw a conflict exception
/// 
/// Example:
/// 
/// ``` dart
/// throw ConflictException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 409
class ConflictException extends SerinusException{
  const ConflictException({String message = "Conflict!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.conflict
  );
}