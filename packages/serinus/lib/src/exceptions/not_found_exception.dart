import 'dart:io';

import 'package:serinus/serinus.dart';

/// The class NotFoundException is used to throw a not found exception
/// 
/// Example:
/// ``` dart
/// throw NotFoundException();
/// ```
/// 
/// The [message] parameter is optional and is used to define the message of the exception
/// 
/// The [uri] parameter is optional and is used to define the uri of the exception
/// 
/// The [statusCode] is 404
class NotFoundException extends SerinusException{
  const NotFoundException({String message = "Not Found!", Uri? uri}) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.notFound
  );
}