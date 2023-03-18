import 'dart:io';

import 'mug_exception.dart';

class NotAcceptableException extends MugException{
  const NotAcceptableException({String message = "Not acceptable!", Uri? uri }) : super(
    message: message, 
    uri: uri, 
    statusCode: HttpStatus.notAcceptable
  );
}