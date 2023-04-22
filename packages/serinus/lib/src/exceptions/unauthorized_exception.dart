import 'dart:io';

import 'package:serinus/src/exceptions/serinus_exception.dart';

/// The class UnauthorizedException is used to throw a unauthorized exception
/// 
/// Example:
/// ``` dart
/// throw UnauthorizedException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 401
class UnauthorizedException extends SerinusException{
  const UnauthorizedException({String message = "Not authorized!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.unauthorized
  );
}