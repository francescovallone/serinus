import 'dart:io';

import 'serinus_exception.dart';

class NotAcceptableException extends SerinusException{
  const NotAcceptableException({String message = "Not acceptable!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.notAcceptable
  );
}