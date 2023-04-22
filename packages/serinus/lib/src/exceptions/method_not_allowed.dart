import 'dart:io';

import 'package:serinus/src/exceptions/serinus_exception.dart';

/// The class MethodNotAllowedException is used to throw a method not allowed exception
/// 
/// Example:
/// ``` dart
/// throw MethodNotAllowedException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 405
class MethodNotAllowedException extends SerinusException{
  const MethodNotAllowedException({String message = "Method not allowed!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.methodNotAllowed
  );
}